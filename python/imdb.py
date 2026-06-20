#!/usr/bin/env python

"""Browse an IMDb watchlist CSV"""

import argparse
import csv
import random
import sys
from pathlib import Path

DEFAULT_FILE = Path.home() / ".cache" / "imdb" / "watchlist.csv"
EXPORTS_URL = "https://www.imdb.com/exports/"
FIELDS = ("title", "runtime", "year")


def load(path: Path) -> list[dict]:
    if not path.exists():
        sys.exit(f"error: watchlist file not found: {path}\n"
                 f"       download it from {EXPORTS_URL} and pass it with -f/--file.")
    with path.open(encoding="utf-8") as f:
        reader = csv.DictReader(f)
        cols = {kw: next((c for c in (reader.fieldnames or []) if kw in c.lower()), "")
                for kw in FIELDS}
        return [{k: (r.get(v) or "").strip() for k, v in cols.items()} for r in reader]


def sort_key(row: dict, key: str):
    if key == "title":
        return row[key].lower()
    if key == "runtime":
        return int(row[key])
    return int(row["year"])


def fmt_runtime(mins: str) -> str:
    m = int(mins)
    return f"{m // 60}:{m % 60:02d}" if m else ""


def line_for(r: dict) -> str:
    return f"{r['title']} ({r["year"]}, {fmt_runtime(r["runtime"])})"


def cmd_list(args):
    rows = load(args.file)
    if args.sort_by:
        rows = sorted(rows, key=lambda r: sort_key(r, args.sort_by), reverse=args.reverse)
    elif args.reverse:
        rows = list(reversed(rows))
    for r in rows:
        print(line_for(r))


def cmd_random(args):
    rows = load(args.file)
    if not rows:
        sys.exit("watchlist is empty")
    print(line_for(random.choice(rows)))


def main():
    p = argparse.ArgumentParser(description="Browse an IMDb watchlist.")
    p.add_argument("-f", "--file", type=Path, default=DEFAULT_FILE,
                   help=f"watchlist CSV file (default: {DEFAULT_FILE})")
    sub = p.add_subparsers(dest="command", required=True)

    lp = sub.add_parser("list", help="list watchlist entries")
    lp.add_argument("-s", "--sort-by", choices=list(FIELDS),
                    default=None, help="sort order (default: CSV order)")
    lp.add_argument("-r", "--reverse", action="store_true", help="reverse order")

    sub.add_parser("random", help="pick a random entry")

    args = p.parse_args()
    {"list": cmd_list, "random": cmd_random}[args.command](args)


if __name__ == "__main__":
    main()
