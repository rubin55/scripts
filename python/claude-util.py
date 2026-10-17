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
TOOL = "claude"


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
#
# ~/.trusted-dirs.toml has tables per tool: "*" for all tools, codex
# or claude for one. ["*".trusted-dirs] maps a dir to a depth. The
# ["*".mcp.enabled] and ["*".mcp.disabled] tables map a trust root to
# "all" or a list of MCP servers, which then keep that state in it.
# Tool tables win over "*" tables. "*" ignores names a tool lacks.


def trusted_dirs_layers():
    # Return the "*" and the tool tables of ~/.trusted-dirs.toml.
    data = load_toml(trusted_dirs_path())
    layers = [data.get("*", {}), data.get(TOOL, {})]
    if not all(isinstance(layer, dict) for layer in layers):
        raise ValueError(f'trusted-dirs.toml: "*" and {TOOL} must be tables')
    return layers


def pin_words(value, root):
    if value == "all":
        return ["all"]
    if isinstance(value, list) and all(isinstance(v, str) for v in value):
        return value
    raise ValueError(f'MCP pin for {root} must be "all" or a list of names')


def mcp_pins(layers, roots):
    # Return (root, enable, disable, strict) for the MCP pins. Only the
    # tool tables are strict about names.
    pins = []
    for layer, strict in zip(layers, (False, True)):
        mcp = layer.get("mcp", {})
        enabled, disabled = mcp.get("enabled", {}), mcp.get("disabled", {})
        for raw in sorted({*enabled, *disabled}):
            root = os.path.normpath(raw)
            if root not in roots:
                raise ValueError(f"MCP pin is not a trust root: {raw}")
            enable = pin_words(enabled.get(raw, []), raw)
            disable = pin_words(disabled.get(raw, []), raw)
            pins.append((root, enable, disable, strict))
    return pins


def known_words(words, names):
    return [word for word in words if word in {"all", *names}]


def expand_trusted_dirs(layers):
    table = {}
    for layer in layers:
        part = layer.get("trusted-dirs", {})
        if not isinstance(part, dict):
            # A bad config file is a value error, main catches only those.
            raise ValueError("trusted-dirs must be a table")  # noqa: TRY004
        table |= part
    if not table:
        raise ValueError('trusted-dirs.toml needs a ["*".trusted-dirs] table')
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


def check_words(servers, words):
    # Words are all, a scope or a server name.
    if unknown := set(words) - {"all", *SCOPES} - {name for _, name, _ in servers}:
        raise ValueError(f"unknown MCP servers or scopes: {', '.join(sorted(unknown))}")


def word_states(servers, enable, disable):
    # Map names to enabled. A name wins over a scope, a scope over all.
    if both := set(enable) & set(disable):
        raise ValueError(f"both enabled and disabled: {', '.join(sorted(both))}")
    states = {}
    for level in range(3):
        for words, state in ((enable, True), (disable, False)):
            for scope, name, _ in servers:
                if ("all", scope, name)[level] in words:
                    states[name] = state
    return states


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
    # Trust the roots and set their disabledMcpServers. All servers are
    # disabled, except those -e enables, then the MCP pins apply.
    layers = trusted_dirs_layers()
    entries = expand_trusted_dirs(layers)
    directories = sorted({os.path.normpath(d) for d in entries})
    config = load_config()
    servers = mcp_servers(config)
    names = {name for _, name, _ in servers}
    check_words(servers, args.enable)
    pins = []
    for root, enable, disable, strict in mcp_pins(layers, set(directories)):
        if strict:
            check_words(servers, enable + disable)
        else:
            enable, disable = known_words(enable, names), known_words(disable, names)
        pins.append((root, enable, disable))
    shared = [server for server in servers if server[0] != "local"]
    if args.no_run:
        print(*directories, sep="\n")
        states = word_states(shared, args.enable, [])
        enabled = sorted(name for name, state in states.items() if state)
        print(f"generate: {len(directories)} trust roots, {len(pins)} MCP pins")
        print(f"generate: enabled MCP servers: {', '.join(enabled) or 'none'}")
        return 0
    projects = config.setdefault("projects", {})
    for project in projects.values():
        project.pop(TRUST_KEY, None)
    for directory in directories:
        project = projects.setdefault(directory, {})
        project[TRUST_KEY] = True
        local = [("local", name, directory) for name in project.get("mcpServers", {})]
        servers_here = shared + local
        states = dict.fromkeys((name for _, name, _ in servers_here), False)
        states |= word_states(servers_here, args.enable, [])
        for root, enable, disable in pins:
            if root == directory:
                states |= word_states(servers_here, enable, disable)
        project[DISABLED_KEY] = sorted(n for n, state in states.items() if not state)
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


# Completion
#
# The case patterns match the words before the cursor. Deeper commands
# come first, so the first match is the most specific one. Values for
# --enable come from "completion LINE". Server names can hold spaces,
# so each value is escaped with printf %q before it is matched.

BASH_COMPLETION = """\
_claude_util() {
    local cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]}
    local line=${COMP_LINE:0:COMP_POINT} path="" word words value
    local re=' (-e|--enable) +((\\\\ |[^ ])*)$'
    if [[ $line =~ $re ]]; then
        local typed=${BASH_REMATCH[2]}
        COMPREPLY=()
        while IFS= read -r value; do
            printf -v value %%q "$value"
            [[ $value == "$typed"* ]] || continue
            # Bash splits cur at COMP_WORDBREAKS, so remove the text before it.
            COMPREPLY+=("${value#"${typed%%"$cur"}"}")
        done < <(%(prog)s completion "$line" 2>/dev/null)
        return
    fi
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
complete -F _claude_util %(prog)s
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


def option_values(_):
    # Return the values for --enable: all, the scopes and server names.
    names = sorted({name for _, name, _ in mcp_servers(load_config())})
    return ["all", *SCOPES, *names]


def completion(parser, line):
    if line is None:
        print(bash_completion(parser), end="")
    else:
        print(*option_values(line), sep="\n")
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
        "-n",
        "--no-run",
        action="store_true",
        help="print roots without writing the config file",
    )
    cmd.set_defaults(func=trust_generate)
    trust.add_parser("purge", help="remove all project entries").set_defaults(
        func=trust_purge
    )

    cmd = groups.add_parser("completion", help="print a bash completion script")
    cmd.add_argument(
        "line", nargs="?", help="print the values for the option at the end of LINE"
    )
    cmd.set_defaults(func=lambda args: completion(parser, args.line))

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except (OSError, ValueError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
