#!/usr/bin/env python3
"""Manage Codex project trust entries in the main config file."""

import argparse
import ast
import os
import re
import sys
import tempfile
import tomllib
from pathlib import Path

TRUST_BLOCK = re.compile(
    r"\n?\[projects\.(?:\"(?:[^\"\\]|\\.)*\"|[^][\n]+)\]\s*\n"
    r"(?:[^\[\n][^\n]*\n?)*?"
    r"trust_level\s*=\s*\"(?:trusted|untrusted)\"\s*\n?"
)
TRUST_ENTRY = re.compile(
    r'\[projects\.("(?:[^"\\]|\\.)*"|[^][\n]+)\]\s*\n'
    r'trust_level\s*=\s*"([^"\n]+)"'
)
LEVELS = {"trusted", "untrusted"}


def config_home():
    return Path(os.environ.get("CODEX_HOME", "~/.codex")).expanduser()


def default_config_path():
    return config_home() / "config.toml"


def trusted_dirs_path():
    return config_home() / "trusted-dirs.toml"


def profile_paths():
    return sorted(config_home().glob("*.config.toml"))


def config_paths():
    return sorted(config_home().glob("*config.toml"))


def list_entries():
    entries = []
    for path in config_paths():
        text = path.read_text()
        for block in TRUST_BLOCK.finditer(text):
            match = TRUST_ENTRY.search(block.group(0))
            if not match:
                continue
            key = parse_key(match.group(1))
            level = match.group(2)
            if key is not None and level in LEVELS:
                entries.append((str(key), level, path.name))
    return sorted(entries)


def quote_key(path):
    return '"' + str(path).replace("\\", "\\\\").replace('"', '\\"') + '"'


def trust_entry(path, level):
    return f'[projects.{quote_key(path)}]\ntrust_level = "{level}"\n\n'


def parse_key(raw_key):
    raw_key = raw_key.strip()
    if raw_key.startswith('"'):
        try:
            return ast.literal_eval(raw_key)
        except (ValueError, SyntaxError):
            return None
    return raw_key


def remove_trust_entries(text):
    blocks = list(TRUST_BLOCK.finditer(text))
    if not blocks:
        return text.rstrip("\n") + "\n", []
    removed = [match.group(0).strip() for match in blocks]
    return TRUST_BLOCK.sub("", text).rstrip("\n") + "\n", removed


def parse_removed_levels(blocks):
    levels = {}
    for block in blocks:
        match = TRUST_ENTRY.search(block)
        if not match:
            continue
        key = parse_key(match.group(1))
        level = match.group(2)
        if key is not None and level in LEVELS:
            levels[key] = level
    return levels


def deduplicate(entries):
    unique = {}
    for directory, level in entries:
        unique[os.path.normpath(str(directory))] = level
    return sorted(unique.items())


def write_file(path, text):
    fd, temporary = tempfile.mkstemp(prefix=f"{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as file:
            file.write(text)
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def write_config(path, text, entries):
    suffix = "".join(trust_entry(directory, level) for directory, level in entries)
    if suffix and not text.endswith("\n"):
        text += "\n"
    if suffix:
        text += "\n" + suffix
    write_file(path, text)


def remove_profile_trust():
    removed = []
    for profile in profile_paths():
        text = profile.read_text()
        text, blocks = remove_trust_entries(text)
        if blocks:
            write_file(profile, text)
            removed.extend(blocks)
    return removed


def consolidate(args):
    path = Path(args.config).expanduser()
    text, blocks = remove_trust_entries(path.read_text())
    blocks.extend(remove_profile_trust())
    entries = deduplicate(parse_removed_levels(blocks).items())
    write_config(path, text, entries)
    print(f"consolidate: wrote {len(entries)} trust roots to {path}")
    return 0


def list_command(args):
    entries = list_entries()
    widths = [
        max([len("level")]
            + [len(level) for _, level, _ in entries]),
        max([len("config")] + [len(filename) for _, _, filename in entries]),
        max([len("path")] + [len(path) for path, _, _ in entries]),
    ]
    if entries:
        header = ("level", "config", "path")
        print("  ".join(name if index == len(widths) - 1 else name.ljust(width) for index, (name, width) in enumerate(zip(header, widths))))
        for path, level, filename in entries:
            row = (level, filename, path)
            print("  ".join(value for value, width in zip(row, widths)))
    return 0


def purge(args):
    path = Path(args.config).expanduser()
    text, blocks = remove_trust_entries(path.read_text())
    blocks.extend(remove_profile_trust())
    write_config(path, text, [])
    print(f"purge: removed {len(blocks)} trust blocks from {path}")
    return 0


def expand_trusted_dirs(path):
    with path.open("rb") as file:
        table = tomllib.load(file).get("trusted-dirs")
    if not isinstance(table, dict):
        raise ValueError("trusted-dirs.toml must contain a [trusted-dirs] table")
    entries = []
    for raw_path, depth in table.items():
        if not isinstance(raw_path, str) or not raw_path.startswith("/"):
            raise ValueError(f"trust path must be absolute: {raw_path!r}")
        if isinstance(depth, bool) or not isinstance(depth, int) or depth < 0:
            raise ValueError(f"depth must be a non-negative integer: {raw_path!r}")
        current = [Path(raw_path).expanduser().resolve(strict=True)]
        if depth == 0:
            entries.append((current[0], "trusted"))
            continue
        for _ in range(depth):
            children = []
            for directory in current:
                if not directory.is_dir() or directory.is_symlink():
                    continue
                children.extend(
                    child
                    for child in directory.iterdir()
                    if child.is_dir()
                    and not child.is_symlink()
                    and not child.name.startswith(".")
                )
            current = sorted(children)
        entries.extend((child, "trusted") for child in current)
    return entries


def generate(args):
    source = Path(args.trusted_dirs).expanduser()
    entries = deduplicate(expand_trusted_dirs(source))
    if args.dry_run:
        for directory, level in entries:
            print(f"{directory} -> {level}")
        print(f"generate: {len(entries)} trust roots")
        return 0
    path = Path(args.config).expanduser()
    text, _ = remove_trust_entries(path.read_text())
    remove_profile_trust()
    write_config(path, text, entries)
    print(f"generate: wrote {len(entries)} trust roots to {path}")
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default=str(default_config_path()))
    parser.add_argument(
        "--trusted-dirs",
        default=str(trusted_dirs_path()),
        help="trusted directory source used by generate",
    )
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser(
        "consolidate", help="deduplicate and move trust roots to the main config"
    )
    commands.add_parser(
        "purge", help="remove all trust roots from the main and profile configs"
    )
    commands.add_parser(
        "list", help="list trust roots found in all Codex config files"
    )
    generate_command = commands.add_parser(
        "generate", help="generate trust roots from trusted-dirs.toml"
    )
    generate_command.add_argument(
        "--dry-run", action="store_true", help="print roots without writing config files"
    )
    args = parser.parse_args(argv)
    try:
        if args.command == "consolidate":
            return consolidate(args)
        if args.command == "purge":
            return purge(args)
        if args.command == "list":
            return list_command(args)
        return generate(args)
    except (OSError, ValueError, tomllib.TOMLDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
