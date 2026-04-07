#!/usr/bin/env python3
"""mimeapps.py - Inspect ~/.config/mimeapps.list associations."""

import os
import argparse
from collections import defaultdict

MIMEAPPS = os.path.expanduser("~/.config/mimeapps.list")
APP_DIRS = [
    "/usr/share/applications",
    os.path.expanduser("~/.local/share/applications"),
]

RED = "\033[31m"
RESET = "\033[0m"
COL = 32


def find_desktop(name):
    filename = name + ".desktop"
    return any(os.path.isfile(os.path.join(d, filename)) for d in APP_DIRS)


def parse_line(line):
    """Parse one line of mimeapps.list.

    Returns ("assoc", mime, [apps]) for mimetype=app[;app...] lines,
    or ("raw", text) for blank lines, section headers, and anything else.
    """
    stripped = line.rstrip("\n")
    if not stripped or stripped.startswith("[") or "=" not in stripped:
        return ("raw", stripped)
    mime, _, apps_str = stripped.partition("=")
    apps = [a.strip() for a in apps_str.split(";") if a.strip()]
    return ("assoc", mime, apps)


def read_entries():
    with open(MIMEAPPS) as f:
        return [parse_line(line) for line in f]


def write_entries(entries):
    lines = []
    for e in entries:
        if e[0] == "raw":
            lines.append(e[1])
        else:
            _, mime, apps = e
            lines.append(f"{mime}={';'.join(apps)}")
    with open(MIMEAPPS, "w") as f:
        f.write("\n".join(lines) + "\n")


def load_associations():
    """Return dict[mimetype] -> list[desktop_name]

    suffix-stripped and deduped across sections.
    """
    assoc = defaultdict(list)
    for e in read_entries():
        if e[0] != "assoc":
            continue
        _, mime, apps = e
        for app in apps:
            name = app.removesuffix(".desktop")
            if name not in assoc[mime]:
                assoc[mime].append(name)
    return assoc


def rewrite(filter_fn):
    """Apply filter_fn(mime, apps) -> kept_apps to every association.

    An empty kept list drops the association line entirely.
    Returns (new_entries, removed_mimes).
    """
    new_entries = []
    removed_mimes = []
    for e in read_entries():
        if e[0] != "assoc":
            new_entries.append(e)
            continue
        _, mime, apps = e
        kept = filter_fn(mime, apps)
        if not kept:
            removed_mimes.append(mime)
            continue
        new_entries.append(("assoc", mime, kept))
    return new_entries, removed_mimes


def tprint(key, value):
    print(f"{key:<{COL}}{value}")


def cmd_by_mime(assoc):
    for mime in sorted(assoc):
        tprint(mime, ", ".join(assoc[mime]))


def cmd_by_app(assoc):
    by_app = defaultdict(set)
    for mime, apps in assoc.items():
        for app in apps:
            by_app[app].add(mime)
    for app in sorted(by_app):
        tprint(app, ", ".join(sorted(by_app[app])))


def cmd_check(assoc):
    apps = {a for app_list in assoc.values() for a in app_list}
    for app in sorted(apps):
        status = "found" if find_desktop(app) else f"{RED}not found{RESET}"
        tprint(app, status)


def cmd_prune():
    removed_apps = set()

    def keep(_, apps):
        kept = []
        for a in apps:
            name = a.removesuffix(".desktop")
            if find_desktop(name):
                kept.append(a)
            else:
                removed_apps.add(name)
        return kept

    new_entries, removed_mimes = rewrite(keep)
    for app in sorted(removed_apps):
        print(f"removed app:  {app}")
    for mime in sorted(removed_mimes):
        print(f"removed mime: {mime}")
    write_entries(new_entries)


def cmd_rm_mime(mime_arg):
    new_entries, removed_mimes = rewrite(
        lambda mime, apps: [] if mime == mime_arg else apps
    )
    if not removed_mimes:
        print(f"no entries found for mime: {mime_arg}")
        return
    for mime in removed_mimes:
        print(f"removed mime: {mime}")
    write_entries(new_entries)


def cmd_rm_app(app_arg):
    target = app_arg if app_arg.endswith(".desktop") else app_arg + ".desktop"
    found = False

    def keep(_, apps):
        nonlocal found
        if target in apps:
            found = True
        return [a for a in apps if a != target]

    new_entries, removed_mimes = rewrite(keep)
    if not found:
        print(f"no entries found for app: {app_arg}")
        return
    print(f"removed app:  {target.removesuffix('.desktop')}")
    for mime in sorted(removed_mimes):
        print(f"removed mime: {mime}")
    write_entries(new_entries)


def main():
    parser = argparse.ArgumentParser(description="Manage mimeapps.list")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("by-mime", help="List entries grouped by MIME type")
    sub.add_parser("by-app", help="List entries grouped by application")
    sub.add_parser("check", help="Check whether app files exist on disk")
    sub.add_parser("prune", help="Remove missing apps from mimeapps.list")
    p_rm_mime = sub.add_parser("rm-mime", help="Remove all entries for a given MIME type")
    p_rm_mime.add_argument("mimetype")
    p_rm_app = sub.add_parser("rm-app", help="Remove an app association from all MIME types")
    p_rm_app.add_argument("app")
    args = parser.parse_args()

    if args.cmd == "prune":
        cmd_prune()
    elif args.cmd == "rm-mime":
        cmd_rm_mime(args.mimetype)
    elif args.cmd == "rm-app":
        cmd_rm_app(args.app)
    else:
        assoc = load_associations()
        if args.cmd == "by-mime":
            cmd_by_mime(assoc)
        elif args.cmd == "by-app":
            cmd_by_app(assoc)
        elif args.cmd == "check":
            cmd_check(assoc)


if __name__ == "__main__":
    main()
