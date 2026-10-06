#!/usr/bin/env python3
"""Sync the user prompt and skills directory to the known agents."""

import argparse
import os
import sys
from pathlib import Path

# Configuration
#
# The agents we know about: where each keeps its user prompt file
# and its skills directory, relative to the home directory.

HOME = Path.home()
PROMPT_DIR = HOME / "Documents/Rubin/Notes"
PROMPT_FILE = PROMPT_DIR / "user-prompt.md"
SKILLS_DIR = HOME / "Documents/Rubin/Skills"

AGENTS = {
    "claude": {
        "prompt": ".claude/CLAUDE.md",
        "skills": ".claude/skills",
    },
    "codex": {
        "prompt": ".codex/AGENTS.md",
        "skills": ".agents/skills",
    },
    "opencode": {
        "prompt": ".config/opencode/AGENTS.md",
        "skills": ".config/opencode/skills",
    },
    "pi": {
        "prompt": ".pi/agent/APPEND_SYSTEM.md",
        "skills": ".pi/agent/skills",
    },
    "zed": {
        "prompt": ".config/zed/AGENTS.md",
        "skills": ".agents/skills",
    },
}


def print_table(headers, rows):
    if not rows:
        return
    widths = [max(len(h), *(len(r[i]) for r in rows)) for i, h in enumerate(headers)]
    for row in [headers, ["-" * w for w in widths], *rows]:
        print("  ".join(c.ljust(w) for c, w in zip(row, widths)).rstrip())


def shorten(path):
    return str(path).replace(str(HOME), "~", 1)


# Prompts


def prompt_extra(name):
    # Agent-specific prompt additions, e.g. user-prompt-for-codex.md.
    for pattern in (f"user-prompt-{name}.md", f"user-prompt-for-{name}.md"):
        path = PROMPT_DIR / pattern
        if path.exists():
            return path
    return None


def prompt_content(name):
    parts = [PROMPT_FILE.read_text().strip("\n")]
    extra = prompt_extra(name)
    if extra:
        lines = extra.read_text().strip("\n").splitlines()
        for i, line in enumerate(lines):
            if line.startswith("#"):
                # Rewrite the header with the agent's capitalized name.
                lines[i] = f"## Additional user prompt for {name.capitalize()}"
                break
        parts.append("\n".join(lines))
    return "\n\n".join(parts) + "\n"


def prompts_list(args):
    rows = []
    for name, agent in AGENTS.items():
        extra = prompt_extra(name)
        rows.append(
            [name, shorten(HOME / agent["prompt"]), shorten(extra) if extra else "-"]
        )
    print_table(["agent", "prompt file", "extra prompt"], rows)
    return 0


def prompts_sync(args):
    for name, agent in AGENTS.items():
        content = prompt_content(name)
        target = HOME / agent["prompt"]
        if not target.parent.is_dir():
            continue
        target.write_text(content)
        print(f"synced {target}")
    return 0


# Skills


def skills_status(target):
    if target.is_symlink():
        link = Path(os.readlink(target))
        return "ok" if link == SKILLS_DIR else f"points to {link}"
    if target.is_dir():
        return "directory"
    if target.exists():
        return "file"
    return "missing"


def skills_list(args):
    rows = []
    for name, agent in AGENTS.items():
        target = HOME / agent["skills"]
        rows.append([name, shorten(target), skills_status(target)])
    print_table(["agent", "skills dir", "status"], rows)
    return 0


def skills_link(args):
    for agent in AGENTS.values():
        target = HOME / agent["skills"]
        if not target.parent.is_dir():
            continue
        if target.is_dir() and not target.is_symlink():
            if any(target.iterdir()):
                print(
                    f"warn: {target} is a non-empty directory, skipping",
                    file=sys.stderr,
                )
                continue
            target.rmdir()
        if target.is_symlink() or target.exists():
            target.unlink()
        target.symlink_to(SKILLS_DIR)
        print(f"linked {target} -> {SKILLS_DIR}")
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.set_defaults(func=lambda _: parser.print_help())
    groups = parser.add_subparsers(title="commands")

    def group(name, help):
        p = groups.add_parser(name, help=help, description=help)
        p.set_defaults(func=lambda _: p.print_help())
        return p.add_subparsers(title="commands")

    prompts = group("prompts", "user prompt files per agent")
    prompts.add_parser("list", help="list agents and their prompt files").set_defaults(
        func=prompts_list
    )
    prompts.add_parser("sync", help="copy the user prompt to each agent").set_defaults(
        func=prompts_sync
    )

    skills = group("skills", "skills directories per agent")
    skills.add_parser(
        "list", help="list agents and their skills directories"
    ).set_defaults(func=skills_list)
    skills.add_parser(
        "link", help="link the skills directory into each agent"
    ).set_defaults(func=skills_link)

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except OSError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
