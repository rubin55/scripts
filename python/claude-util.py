#!/usr/bin/env python3
"""Manage project trust and MCP server entries in ~/.claude.json."""

import argparse
import json
import os
import sys
import tempfile
import tomllib
from pathlib import Path

TRUST_KEY = "hasTrustDialogAccepted"
DISABLED_KEY = "disabledMcpServers"
SCOPES = ["claude.ai", "local", "user"]


def config_path():
    home = os.environ.get("CLAUDE_CONFIG_DIR", "~")
    return Path(home).expanduser() / ".claude.json"


def trusted_dirs_path():
    return Path("~/.trusted-dirs.toml").expanduser()


def load_toml(path):
    with open(path, "rb") as f:
        return tomllib.load(f)


def load_config():
    with open(config_path()) as f:
        return json.load(f)


def save_config(config):
    write_file(config_path(), json.dumps(config, indent=2, ensure_ascii=False))


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


def print_table(headers, rows):
    if not rows:
        return
    widths = [max(len(h), *(len(r[i]) for r in rows)) for i, h in enumerate(headers)]
    for row in [headers, ["-" * w for w in widths], *rows]:
        print("  ".join(c.ljust(w) for c, w in zip(row, widths)).rstrip())


# Trust roots
#
# Claude Code trusts a directory when it, or one of its parents, has
# projects[<path>].hasTrustDialogAccepted set to true. The names in
# projects[<path>].disabledMcpServers are not started in that project.
# Claude Code uses the git root as the project path, or else the cwd.


def expand_trusted_dirs(path):
    table = load_toml(path).get("trusted-dirs")
    if not isinstance(table, dict):
        # A bad config file is a value error, main catches only those.
        raise ValueError(  # noqa: TRY004
            "trusted-dirs.toml must contain a [trusted-dirs] table"
        )
    entries = []
    for raw_path, depth in table.items():
        if not isinstance(raw_path, str) or not raw_path.startswith("/"):
            raise ValueError(f"trust path must be absolute: {raw_path!r}")
        if isinstance(depth, bool) or not isinstance(depth, int) or depth < 0:
            raise ValueError(f"depth must be a non-negative integer: {raw_path!r}")
        current = [Path(raw_path).resolve(strict=True)]
        for _ in range(depth):
            current = sorted(
                child
                for directory in current
                if directory.is_dir()
                for child in directory.iterdir()
                if child.is_dir()
                and not child.is_symlink()
                and not child.name.startswith(".")
            )
        entries.extend(current)
    return entries


def mcp_servers(config):
    # Return (scope, name, project) for the MCP servers in the config.
    servers = [("user", name, "") for name in config.get("mcpServers", {})]
    servers += [
        ("claude.ai", name, "") for name in config.get("claudeAiMcpEverConnected", [])
    ]
    servers += [
        ("local", name, path)
        for path, project in config.get("projects", {}).items()
        for name in project.get("mcpServers", {})
    ]
    return sorted(servers)


def select_servers(servers, words):
    # Return the names that words select: all, a scope or a server name.
    words = set(words)
    if unknown := words - {"all", *SCOPES} - {name for _, name, _ in servers}:
        raise ValueError(f"unknown MCP servers or scopes: {', '.join(sorted(unknown))}")
    return {name for scope, name, _ in servers if {"all", scope, name} & words}


def mcp_list(_):
    print_table(["scope", "name", "project"], mcp_servers(load_config()))
    return 0


def trust_list(_):
    projects = load_config().get("projects", {})
    rows = [
        ["trusted" if project.get(TRUST_KEY) else "untrusted", key]
        for key, project in sorted(projects.items())
    ]
    print_table(["level", "path"], rows)
    return 0


def trust_generate(args):
    entries = expand_trusted_dirs(trusted_dirs_path())
    directories = sorted({os.path.normpath(d) for d in entries})
    config = load_config()
    servers = mcp_servers(config)
    enabled = select_servers(servers, args.enable)
    if args.dry_run:
        print(*directories, sep="\n")
        print(f"generate: {len(directories)} trust roots")
        print(f"generate: enabled MCP servers: {', '.join(sorted(enabled)) or 'none'}")
        return 0
    shared = {name for scope, name, _ in servers if scope != "local"}
    projects = config.setdefault("projects", {})
    for project in projects.values():
        project.pop(TRUST_KEY, None)
    for directory in directories:
        project = projects.setdefault(directory, {})
        project[TRUST_KEY] = True
        local = project.get("mcpServers", {})
        project[DISABLED_KEY] = sorted((shared | set(local)) - enabled)
    save_config(config)
    print(f"generate: wrote {len(directories)} trust roots to {config_path()}")
    return 0


def trust_purge(_):
    config = load_config()
    removed = len(config.get("projects", {}))
    config["projects"] = {}
    save_config(config)
    print(f"purge: removed {removed} projects from {config_path()}")
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.set_defaults(func=lambda _: parser.print_help())
    groups = parser.add_subparsers(title="commands")

    def group(name, help):
        p = groups.add_parser(name, help=help, description=help)
        p.set_defaults(func=lambda _: p.print_help())
        return p.add_subparsers(title="commands")

    mcp = group("mcp-servers", "MCP servers known to Claude Code")
    mcp.add_parser("list", help="list MCP servers and their scope").set_defaults(
        func=mcp_list
    )

    trust = group("trust-roots", "project entries")
    trust.add_parser("list", help="list projects and their trust level").set_defaults(
        func=trust_list
    )
    cmd = trust.add_parser(
        "generate",
        help="generate trust roots from ~/.trusted-dirs.toml, "
        "with all MCP servers disabled",
    )
    cmd.add_argument(
        "-e",
        "--enable",
        action="append",
        default=[],
        metavar="NAME",
        help="keep MCP servers enabled: all, a scope (claude.ai, local, user) "
        "or a server name (repeatable)",
    )
    cmd.add_argument(
        "-d",
        "--dry-run",
        action="store_true",
        help="print roots without writing the config file",
    )
    cmd.set_defaults(func=trust_generate)
    trust.add_parser("purge", help="remove all project entries").set_defaults(
        func=trust_purge
    )

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except (OSError, ValueError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
