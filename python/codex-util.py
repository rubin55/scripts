#!/usr/bin/env python3
"""Manage Codex model catalogs, profiles and trust roots in $CODEX_HOME."""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import tomllib
import urllib.error
import urllib.request
from pathlib import Path


def codex_home():
    return Path(os.environ.get("CODEX_HOME", "~/.codex")).expanduser()


def config_path():
    return codex_home() / "config.toml"


def profile_paths():
    return sorted(codex_home().glob("*.config.toml"))


def config_paths():
    return [config_path(), *profile_paths()]


def load_toml(path):
    with open(path, "rb") as f:
        return tomllib.load(f)


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


# Model catalogs
#
# Reads model_providers from config.toml and the profile configs,
# fetches <base_url>/models?client_version=... and writes
# model-catalogs/<provider>.json in the Codex {"models": [...]} format.
#
# Providers that already serve the Codex format (OpenRouter and
# compatible routers check the codex-cli User-Agent) are saved as-is.
# Providers that serve the standard OpenAI {"data": [...]} list get
# each entry translated to a minimal ModelInfo. base_instructions is
# copied from the bundled catalog so entries keep the builtin prompt.

EFFORT_DESCRIPTIONS = {
    "minimal": "Fastest responses with minimal reasoning",
    "low": "Fast responses with lighter reasoning",
    "medium": "Balanced speed and reasoning depth",
    "high": "Deep reasoning for complex problems",
    "xhigh": "Extra-deep reasoning for the hardest problems",
    "max": "Maximum reasoning depth for the hardest problems",
    "ultra": "Maximum reasoning with automatic task delegation",
    "none": "No reasoning",
}


def run_capture(argv, timeout=30):
    try:
        out = subprocess.run(
            argv, capture_output=True, text=True, timeout=timeout, check=False
        )
    except (OSError, subprocess.SubprocessError) as e:
        return None, str(e)
    if out.returncode != 0:
        return None, out.stderr.strip()[:200]
    return out.stdout, None


def resolve_token(key, info):
    auth = info.get("auth")
    if isinstance(auth, dict) and auth.get("command"):
        argv = [auth["command"], *map(str, auth.get("args", []))]
        out, err = run_capture(argv, timeout=15)
        if out is None:
            print(f"warn: {key}: auth command failed: {err}", file=sys.stderr)
            return None
        lines = out.strip().splitlines()
        return lines[0].strip() if lines else None
    env_key = info.get("env_key")
    if env_key and os.environ.get(env_key):
        return os.environ[env_key]
    token = info.get("experimental_bearer_token")
    return str(token) if token else None


def codex_client_version(codex_bin):
    out, _ = run_capture([codex_bin, "--version"])
    if out:
        for tok in out.replace(",", " ").split():
            if tok and tok[0].isdigit():
                return tok.strip()
    return "0.155.1"


def bundled_base_instructions(codex_bin):
    out, err = run_capture([codex_bin, "debug", "models", "--bundled"])
    if not out:
        print(f"warn: cannot read bundled catalog: {err}", file=sys.stderr)
        return None
    try:
        data = json.loads(out)
    except json.JSONDecodeError as e:
        print(f"warn: bundled catalog not JSON: {e}", file=sys.stderr)
        return None
    for m in data.get("models", []):
        if m.get("base_instructions"):
            return m["base_instructions"]
        mm = m.get("model_messages") or {}
        if mm.get("instructions_template"):
            return mm["instructions_template"]
    return None


def fetch_models(base_url, token, timeout, client_version=None):
    # With a client version, Codex-aware routers serve the native format.
    url = base_url.rstrip("/") + "/models"
    headers = {"Accept": "application/json"}
    if client_version:
        url += f"?client_version={client_version}"
        headers["User-Agent"] = f"codex-cli/{client_version}"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.load(resp), None
    except urllib.error.HTTPError as e:
        try:
            body = e.read().decode()[:200]
        except (OSError, ValueError, UnicodeDecodeError):
            body = ""
        return None, f"HTTP {e.code}: {body}"
    except (urllib.error.URLError, OSError, ValueError, json.JSONDecodeError) as e:
        return None, str(e)[:200]


def first_int(*vals):
    for v in vals:
        if isinstance(v, bool):
            continue
        if isinstance(v, int) and v > 0:
            return v
        if isinstance(v, float) and v > 0:
            return int(v)
    return None


def as_dict(v):
    return v if isinstance(v, dict) else {}


def as_str_list(v):
    return [e for e in v if isinstance(e, str)] if isinstance(v, list) else []


def translate_entry(item, index, base_instructions):
    meta = as_dict(item.get("metadata"))
    limits = as_dict(meta.get("limits"))
    arch = as_dict(item.get("architecture"))
    caps = {**as_dict(item.get("capabilities")), **as_dict(meta.get("capabilities"))}
    reasoning = [as_dict(meta.get("reasoning")), as_dict(item.get("reasoning"))]

    model_id = str(item.get("id", f"unknown-{index}"))
    display = (
        meta.get("display_name")
        or item.get("name")
        or item.get("canonical_slug")
        or model_id
    )
    desc = item.get("description") or meta.get("description") or ""
    ctx = first_int(
        item.get("max_model_len"),
        item.get("context_size"),
        item.get("context_length"),
        item.get("contextLength"),
        limits.get("max_context_length"),
    )

    efforts = []
    for r in reasoning:
        efforts += as_str_list(r.get("supported_efforts"))
        efforts += as_str_list(r.get("accepted_efforts"))
    default_effort = next(
        (
            r["default_effort"]
            for r in reasoning
            if isinstance(r.get("default_effort"), str)
        ),
        None,
    )
    if default_effort:
        efforts.append(default_effort)
    efforts = list(dict.fromkeys(efforts))

    modalities = []
    for src in (
        item.get("input_modalities"),
        arch.get("input_modalities"),
        caps.get("input_modalities"),
    ):
        for m in as_str_list(src):
            m = m.lower()
            if m in ("text", "image", "audio") and m not in modalities:
                modalities.append(m)
    if not modalities:
        tags = [t.lower() for t in as_str_list(item.get("tags"))]
        modalities = ["text"]
        if "image" in tags or caps.get("vision"):
            modalities.append("image")

    feats = {f.lower() for f in as_str_list(item.get("supported_features"))}
    params = {p.lower() for p in as_str_list(item.get("supported_parameters"))}
    parallel = bool(
        caps.get("supports_parallel_function_calling")
        or caps.get("supports_function_calling")
        or caps.get("tools")
        or "tools" in feats
        or "tools" in params
    )

    entry = {
        "slug": model_id,
        "display_name": str(display),
        "description": str(desc),
        "supported_reasoning_levels": [
            {"effort": e, "description": EFFORT_DESCRIPTIONS.get(e, f"{e} reasoning")}
            for e in efforts
        ],
        "shell_type": "default",
        "visibility": "list",
        "supported_in_api": True,
        "priority": 100 + index,
        "support_verbosity": False,
        "default_verbosity": None,
        "apply_patch_tool_type": None,
        "truncation_policy": {"mode": "bytes", "limit": 10000},
        "supports_parallel_tool_calls": parallel,
        "experimental_supported_tools": [],
        "input_modalities": modalities,
    }
    if default_effort:
        entry["default_reasoning_level"] = default_effort
    if ctx:
        entry["context_window"] = ctx
        entry["max_context_window"] = ctx
    if base_instructions:
        entry["base_instructions"] = base_instructions
    else:
        entry["model_messages"] = {"instructions_template": "You are a coding agent."}
    return entry


def translate_models(data, base_instructions, start=0):
    return [
        translate_entry(m, start + i, base_instructions)
        for i, m in enumerate(data)
        if isinstance(m, dict)
    ]


def merge_models(models, extra):
    # Append the extra models with a new slug, return how many.
    known = {m.get("slug") for m in models}
    new = [m for m in extra if isinstance(m, dict) and m.get("slug") not in known]
    models.extend(new)
    return len(new)


def read_models(path):
    with open(path) as f:
        return json.load(f).get("models", [])


def provider_models(key, info, timeout, client_version, base_instructions):
    # Return the models and a label, or None and an error.
    base_url = info.get("base_url")
    if not base_url:
        return None, "no base_url"
    token = resolve_token(key, info)
    payload, err = fetch_models(str(base_url), token, timeout, client_version)
    if err:
        return None, err
    if not isinstance(payload.get("models"), list):
        if not isinstance(payload.get("data"), list):
            return None, f"unexpected shape, keys: {sorted(payload)}"
        return translate_models(payload["data"], base_instructions), "translated"
    # Add translated entries for ids missing from a native catalog.
    models, label = payload["models"], "native"
    plain, err = fetch_models(str(base_url), token, timeout)
    if err:
        print(f"warn {key}: plain list failed: {err}", file=sys.stderr)
    elif isinstance(plain.get("data"), list):
        extra = translate_models(plain["data"], base_instructions, len(models))
        added = merge_models(models, extra)
        if added:
            label += f"+{added} translated"
    return models, label


def catalogs_list(args):
    rows = [
        [path.stem, str(m.get("slug", "-"))]
        for path in sorted(Path(args.dir).glob("*.json"))
        for m in read_models(path)
    ]
    print_table(["catalog", "slug"], rows)
    return 0


def catalogs_generate(args):
    providers = {}
    for path in config_paths():
        for key, info in load_toml(path).get("model_providers", {}).items():
            if isinstance(info, dict):
                providers.setdefault(key, info)
    if args.provider:
        providers = {k: v for k, v in providers.items() if k in args.provider}
    if not providers:
        print("error: no matching providers", file=sys.stderr)
        return 2

    client_version = args.client_version or codex_client_version(args.codex_bin)
    base_instructions = bundled_base_instructions(args.codex_bin)
    if not base_instructions:
        print("warn: no bundled instructions, using stub", file=sys.stderr)

    out_dir = Path(args.dir)
    if not args.dry_run:
        out_dir.mkdir(parents=True, exist_ok=True)
    failures = 0
    for key, info in providers.items():
        models, label = provider_models(
            key, info, args.timeout, client_version, base_instructions
        )
        if models is None:
            print(f"fail {key}: {label}", file=sys.stderr)
            failures += 1
            continue
        # Keep models from the previous file that the provider no longer lists.
        path = out_dir / f"{key}.json"
        if not args.dry_run and path.is_file():
            kept = merge_models(models, read_models(path))
            if kept:
                label += f"+{kept} kept"
        models.sort(key=lambda m: m.get("slug", ""))
        if not args.dry_run:
            write_file(path, json.dumps({"models": models}, indent=1) + "\n")
        if not args.quiet:
            done = f"ok {key}" if args.dry_run else f"wrote {path}"
            print(f"{done}: {len(models)} models ({label})")
    return 1 if failures else 0


# Profiles


def profiles_list(args):
    rows = []
    for path in profile_paths():
        data = load_toml(path)
        rows.append(
            [
                path.name.removesuffix(".config.toml"),
                data.get("model_provider", "-"),
                data.get("model", "-").rsplit("/", 1)[-1],
                data.get("model_reasoning_effort", "-"),
            ]
        )
    print_table(["profile", "provider", "model", "effort"], rows)
    return 0


# Trust roots

TRUST_BLOCK = re.compile(
    r"\n?\[projects\.(?:\"(?:[^\"\\]|\\.)*\"|[^][\n]+)\]\s*\n"
    r"(?:[^\[\n][^\n]*\n?)*?"
    r"trust_level\s*=\s*\"(?:trusted|untrusted)\"\s*\n?"
)


def trust_entry(path, level):
    key = '"' + str(path).replace("\\", "\\\\").replace('"', '\\"') + '"'
    return f'[projects.{key}]\ntrust_level = "{level}"\n'


def parse_block(block):
    # Return (path, level) from one trust block, None if not valid.
    try:
        ((key, table),) = tomllib.loads(block)["projects"].items()
        return key, table["trust_level"]
    except (ValueError, KeyError, TypeError):
        return None


def trust_entries():
    # Return (path, level, config name) for the trust blocks in all configs.
    return [
        (*entry, path.name)
        for path in config_paths()
        for match in TRUST_BLOCK.finditer(path.read_text())
        if (entry := parse_block(match.group(0)))
    ]


def deduplicate(entries):
    return sorted({os.path.normpath(d): level for d, level in entries}.items())


def replace_trust(entries):
    # Remove trust blocks from all configs, add entries to the main one.
    removed = 0
    for path in config_paths():
        old = path.read_text()
        text, count = TRUST_BLOCK.subn("", old)
        text = text.rstrip("\n") + "\n"
        if path == config_path():
            text = "\n".join([text, *(trust_entry(*e) for e in entries)])
        if text != old:
            write_file(path, text)
        removed += count
    return removed


def expand_trusted_dirs(path):
    table = load_toml(path).get("trusted-dirs")
    if not isinstance(table, dict):
        raise ValueError("trusted-dirs.toml must contain a [trusted-dirs] table")
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
        entries.extend((directory, "trusted") for directory in current)
    return entries


def trust_list(args):
    rows = [[level, name, key] for key, level, name in sorted(trust_entries())]
    print_table(["level", "config", "path"], rows)
    return 0


def trust_generate(args):
    entries = deduplicate(expand_trusted_dirs(codex_home() / "trusted-dirs.toml"))
    if args.dry_run:
        for directory, level in entries:
            print(f"{directory} -> {level}")
        print(f"generate: {len(entries)} trust roots")
        return 0
    replace_trust(entries)
    print(f"generate: wrote {len(entries)} trust roots to {config_path()}")
    return 0


def trust_consolidate(args):
    entries = deduplicate((key, level) for key, level, _ in trust_entries())
    replace_trust(entries)
    print(f"consolidate: wrote {len(entries)} trust roots to {config_path()}")
    return 0


def trust_purge(args):
    removed = replace_trust([])
    print(f"purge: removed {removed} trust blocks from all configs")
    return 0


# Completion
#
# The case patterns match the words before the cursor. Deeper commands
# come first, so the first match is the most specific one.

BASH_COMPLETION = """\
_codex_util() {
    local cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]}
    local path="" word words
    case $prev in
        %(value_options)s) compopt -o default; COMPREPLY=(); return ;;
    esac
    for word in "${COMP_WORDS[@]:1:COMP_CWORD-1}"; do
        path+="$word "
    done
    case $path in
%(cases)s
    esac
    COMPREPLY=($(compgen -W "$words" -- "$cur"))
}
complete -F _codex_util %(prog)s
"""


def bash_completion(parser):
    cases, value_options = [], set()

    def walk(p, path):
        words = []
        for action in p._actions:
            if isinstance(action, argparse._SubParsersAction):
                for name, sub in action.choices.items():
                    walk(sub, f"{path}{name} ")
                    words.append(name)
            else:
                words += action.option_strings
                if action.nargs != 0:
                    value_options.update(action.option_strings)
        cases.append(f'        "{path}"*) words="{" ".join(words)}" ;;')

    walk(parser, "")
    return BASH_COMPLETION % {
        "value_options": "|".join(sorted(value_options)),
        "cases": "\n".join(cases),
        "prog": parser.prog,
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.set_defaults(func=lambda _: parser.print_help())
    groups = parser.add_subparsers(title="commands")

    def group(name, help):
        p = groups.add_parser(name, help=help, description=help)
        p.set_defaults(func=lambda _: p.print_help())
        return p.add_subparsers(title="commands")

    catalogs_dir = str(codex_home() / "model-catalogs")
    catalogs = group("model-catalogs", "model catalog files per provider")
    cmd = catalogs.add_parser("list", help="list the models in each catalog")
    cmd.add_argument("--dir", default=catalogs_dir)
    cmd.set_defaults(func=catalogs_list)
    cmd = catalogs.add_parser(
        "generate", help="generate model catalogs from configured providers"
    )
    cmd.add_argument("--dir", default=catalogs_dir)
    cmd.add_argument(
        "--provider",
        action="append",
        default=[],
        help="only this provider (repeatable)",
    )
    cmd.add_argument("--timeout", type=int, default=20)
    cmd.add_argument("--client-version")
    cmd.add_argument("--codex-bin", default="codex")
    cmd.add_argument(
        "--dry-run", action="store_true", help="fetch and translate, do not write files"
    )
    cmd.add_argument("--quiet", action="store_true")
    cmd.set_defaults(func=catalogs_generate)

    profiles = group("profiles", "profile config files")
    profiles.add_parser("list", help="list profiles").set_defaults(func=profiles_list)

    trust = group("trust-roots", "project trust entries")
    trust.add_parser(
        "list", help="list trust roots found in all Codex config files"
    ).set_defaults(func=trust_list)
    cmd = trust.add_parser(
        "generate", help="generate trust roots from trusted-dirs.toml"
    )
    cmd.add_argument(
        "--dry-run",
        action="store_true",
        help="print roots without writing config files",
    )
    cmd.set_defaults(func=trust_generate)
    trust.add_parser(
        "consolidate", help="deduplicate and move trust roots to the main config"
    ).set_defaults(func=trust_consolidate)
    trust.add_parser(
        "purge", help="remove all trust roots from the main and profile configs"
    ).set_defaults(func=trust_purge)

    groups.add_parser("completion", help="print a bash completion script").set_defaults(
        func=lambda _: print(bash_completion(parser), end="")
    )

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except (OSError, ValueError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
