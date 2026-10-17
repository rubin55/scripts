#!/usr/bin/env python3
"""Manage site permissions in permissions.sqlite of a Firefox profile."""

import argparse
import configparser
import contextlib
import fcntl
import os
import sqlite3
import sys
import time
from pathlib import Path

FIREFOX = Path("~/.mozilla/firefox").expanduser()
DEFAULT_TYPE = "persist-data-on-shutdown"
COLUMNS = (
    "origin",
    "type",
    "permission",
    "expireType",
    "expireTime",
    "modificationTime",
)
INSERT = f"INSERT INTO moz_perms ({', '.join(COLUMNS)}) VALUES ({', '.join('?' * len(COLUMNS))})"
PERMISSIONS = {1: "allow", 2: "deny", 3: "prompt", 8: "session"}
EXPIRES = {0: "never", 1: "session", 3: "policy"}
ALLOW = 1


def default_profile():
    # Use the install default, then the Default=1 profile, then any.
    ini = configparser.ConfigParser()
    ini.read(FIREFOX / "profiles.ini")
    sections = [ini[name] for name in ini.sections()]
    paths = [
        s["Default"]
        for s in sections
        if s.name.startswith("Install") and "Default" in s
    ]
    profiles = [s for s in sections if s.name.startswith("Profile") and "Path" in s]
    paths += [s["Path"] for s in profiles if s.get("Default") == "1"]
    paths += [s["Path"] for s in profiles]
    if not paths:
        raise ValueError(f"no profile in {FIREFOX / 'profiles.ini'}")
    return FIREFOX / paths[0]


@contextlib.contextmanager
def open_db(profile, write=False):
    # Firefox holds an fcntl lock on .parentlock while it runs. We take
    # it too, so Firefox cannot start while we work. Firefox also locks
    # the database, so we read a running profile as immutable.
    path = profile / "permissions.sqlite"
    if not path.is_file():
        raise ValueError(f"no permissions database: {path}")
    fd = os.open(profile / ".parentlock", os.O_RDWR | os.O_CREAT, 0o644)
    try:
        try:
            fcntl.lockf(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            mode = "rw" if write else "ro"
        except (BlockingIOError, PermissionError):
            if write:
                raise RuntimeError(
                    f"Firefox is running with profile {profile}"
                ) from None
            mode = "ro&immutable=1"
        db = sqlite3.connect(f"{path.as_uri()}?mode={mode}", uri=True)
        try:
            with db:
                yield db
        finally:
            db.close()
    finally:
        os.close(fd)


def origin(value):
    # Accept a bare host as an https origin.
    value = value.rstrip("/")
    return value if "://" in value else f"https://{value}"


def expires(expire_type, expire_time):
    if expire_type in EXPIRES:
        return EXPIRES[expire_type]
    return time.strftime("%Y-%m-%d %H:%M", time.localtime(expire_time / 1000))


def print_table(headers, rows):
    if not rows:
        return
    widths = [max(len(h), *(len(r[i]) for r in rows)) for i, h in enumerate(headers)]
    for row in [headers, ["-" * w for w in widths], *rows]:
        print("  ".join(c.ljust(w) for c, w in zip(row, widths)).rstrip())


def put(db, row):
    db.execute("DELETE FROM moz_perms WHERE origin = ? AND type = ?", row[:2])
    db.execute(INSERT, row)


def parse_dump(text):
    rows = []
    for number, line in enumerate(text.splitlines(), 1):
        if not line.strip():
            continue
        fields = line.split("\t")
        try:
            if len(fields) != len(COLUMNS):
                raise ValueError
            rows.append((*fields[:2], *map(int, fields[2:])))
        except ValueError:
            raise ValueError(f"line {number}: expected {', '.join(COLUMNS)}") from None
    return rows


def cmd_list(args):
    with open_db(args.profile) as db:
        rows = db.execute(
            "SELECT origin, type, permission, expireType, expireTime FROM moz_perms"
            " WHERE ? IS NULL OR type = ? ORDER BY origin, type",
            (args.type, args.type),
        ).fetchall()
    rows = [[o, t, PERMISSIONS.get(p, str(p)), expires(e, x)] for o, t, p, e, x in rows]
    print_table(["origin", "type", "permission", "expires"], rows)
    return 0


def cmd_add(args):
    now = int(time.time() * 1000)
    with open_db(args.profile, write=True) as db:
        for o in args.origins:
            put(db, (o, args.type, ALLOW, 0, 0, now))
            print(f"add: {args.type} for {o}")
    return 0


def cmd_remove(args):
    with open_db(args.profile, write=True) as db:
        for o in args.origins:
            cursor = db.execute(
                "DELETE FROM moz_perms WHERE origin = ? AND type = ?", (o, args.type)
            )
            print(f"remove: {cursor.rowcount} {args.type} for {o}")
    return 0


def cmd_dump(args):
    with open_db(args.profile) as db:
        rows = db.execute(
            f"SELECT {', '.join(COLUMNS)} FROM moz_perms ORDER BY id"
        ).fetchall()
    for row in rows:
        print(*row, sep="\t")
    return 0


def cmd_restore(args):
    text = sys.stdin.read() if args.file == "-" else Path(args.file).read_text()
    rows = parse_dump(text)
    with open_db(args.profile, write=True) as db:
        db.execute("DELETE FROM moz_perms")
        db.executemany(INSERT, rows)
    print(f"restore: wrote {len(rows)} permissions to {args.profile}")
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "-p",
        "--profile",
        type=Path,
        help="profile directory (default: the default profile in profiles.ini)",
    )
    parser.set_defaults(func=lambda _: parser.print_help())
    commands = parser.add_subparsers(title="commands")

    def type_option(cmd, default):
        cmd.add_argument(
            "-t",
            "--type",
            default=default,
            help=f"permission type (default: {default or 'all'})",
        )

    cmd = commands.add_parser("list", help="list permissions")
    type_option(cmd, None)
    cmd.set_defaults(func=cmd_list)

    for name, func, help in (
        ("add", cmd_add, "allow a permission for origins"),
        ("remove", cmd_remove, "remove a permission for origins"),
    ):
        cmd = commands.add_parser(name, help=f"{help} (Firefox must not run)")
        cmd.add_argument(
            "origins",
            nargs="+",
            type=origin,
            metavar="ORIGIN",
            help="origin, or a host for https://HOST",
        )
        type_option(cmd, DEFAULT_TYPE)
        cmd.set_defaults(func=func)

    cmd = commands.add_parser("dump", help="print all permissions as TSV")
    cmd.set_defaults(func=cmd_dump)

    cmd = commands.add_parser(
        "restore", help="replace all permissions with a dump (Firefox must not run)"
    )
    cmd.add_argument("file", metavar="FILE", help="dump file, or - for stdin")
    cmd.set_defaults(func=cmd_restore)

    args = parser.parse_args(argv)
    try:
        args.profile = args.profile or default_profile()
        return args.func(args)
    except (OSError, RuntimeError, ValueError, sqlite3.Error) as e:
        print(f"error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
