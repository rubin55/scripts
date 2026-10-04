#!/usr/bin/env python

import argparse
import glob
import random
import subprocess
import sys
import termios
import tty
from pathlib import Path


def tokenize(content: str) -> list[str]:
    tokens = []
    i = 0
    while i < len(content):
        c = content[i]
        if c in ' \t\n\r':
            i += 1
        elif c == '{':
            tokens.append('{')
            i += 1
        elif c == '}':
            tokens.append('}')
            i += 1
        elif c == '"':
            j = i + 1
            while j < len(content) and content[j] != '"':
                if content[j] == '\\':
                    j += 1
                j += 1
            tokens.append(content[i + 1:j])
            i = j + 1
        else:
            i += 1
    return tokens


def parse(tokens: list[str], i: int) -> tuple[dict, int]:
    result = {}
    while i < len(tokens):
        if tokens[i] == '}':
            return result, i + 1
        key = tokens[i]
        i += 1
        if i < len(tokens) and tokens[i] == '{':
            i += 1
            value, i = parse(tokens, i)
        else:
            value = tokens[i]
            i += 1
        result[key] = value
    return result, i


def read_vdf(path: str) -> dict:
    with open(path, 'r') as f:
        content = f.read()
    result, _ = parse(tokenize(content), 0)
    return result


def read_playtimes(steam_dir: Path) -> dict[str, int]:
    # Playtime in minutes per app id, from the most recent user.
    playtimes = {}
    pattern = str(steam_dir / "userdata" / "*" / "config" / "localconfig.vdf")
    candidates = glob.glob(pattern)
    if not candidates:
        return playtimes
    latest = max(candidates, key=lambda p: Path(p).stat().st_mtime)
    store = read_vdf(latest)
    apps = store.get("UserLocalConfigStore", {})
    for key in ("Software", "Valve", "Steam", "apps"):
        apps = apps.get(key, {}) if isinstance(apps, dict) else {}
    for app_id, entry in apps.items():
        if isinstance(entry, dict) and "Playtime" in entry:
            try:
                playtimes[app_id] = int(entry["Playtime"])
            except ValueError:
                pass
    return playtimes


def read_installed_games(steam_dir: Path) -> list[dict]:
    pattern = str(steam_dir / "steamapps" / "appmanifest_*.acf")
    games = []
    for acf_file in glob.glob(pattern):
        app_state = read_vdf(acf_file).get("AppState", {})
        if "appid" in app_state and "name" in app_state:
            games.append({"appid": app_state["appid"], "name": app_state["name"]})
    return games


def get_character() -> str:
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setcbreak(fd)
        return sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)


UNITS = {"m": 1, "h": 60, "d": 60 * 24}


def to_minutes(amount: str) -> float:
    # An amount is a number plus a unit: 60m, 2h, 1d.
    try:
        return float(amount[:-1]) * UNITS[amount[-1]]
    except (KeyError, ValueError, IndexError):
        raise argparse.ArgumentTypeError(
            f"invalid amount: {amount!r}, use a number plus m, h or d")


def parse_time(value: str) -> tuple[float, float | None]:
    # "1h+" means 1 hour or more, "1-2d" means 1 to 2 days.
    # A unit at the end of the range applies to both bounds.
    # A single amount is exact: "0m" matches 0 minutes of playtime.
    err = argparse.ArgumentTypeError(
        f"invalid time: {value!r}, use T, MIN-MAX or MIN+ with m, h or d")
    if value.endswith("+"):
        return to_minutes(value[:-1]), None
    if "-" in value:
        lo, hi = value.split("-", 1)
        if hi and hi[-1] in UNITS and (not lo or lo[-1] not in UNITS):
            lo += hi[-1]
        lo, hi = to_minutes(lo), to_minutes(hi)
        if lo <= hi:
            return lo, hi
    else:
        exact = to_minutes(value)
        return exact, exact
    raise err


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="steam-util.py",
        description="List installed Steam games or pick one at random.")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("-l", "--list", action="store_true",
                      help="list installed games, one per line")
    mode.add_argument("-r", "--random", action="store_true",
                      help="pick a random game and offer to start it")
    parser.add_argument("-t", "--time", type=parse_time, metavar="RANGE",
                        help="filter by time played: T, MIN-MAX or MIN+, amounts use m, h or d (e.g. 0m, 30m-2h)")
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(0)
    args = parser.parse_args()

    steam_dir = Path.home() / "Steam"
    games = read_installed_games(steam_dir)
    if not games:
        print("no installed games found", file=sys.stderr)
        sys.exit(1)

    if args.time is not None:
        lo, hi = args.time
        playtimes = read_playtimes(steam_dir)
        games = [g for g in games
                 if lo <= playtimes.get(g["appid"], 0) and
                 (hi is None or playtimes.get(g["appid"], 0) <= hi)]
        if not games:
            print("no games match the time range", file=sys.stderr)
            sys.exit(1)

    if args.list:
        for game in sorted(games, key=lambda g: g["name"].lower()):
            print(game["name"])
        return

    while True:
        game = random.choice(games)
        print(f'{game["name"]} (y/n/c) ', end='', flush=True)
        key = get_character()
        print(key)
        if key == 'y' or key == '\n':
            subprocess.Popen(["steam", f'steam://rungameid/{game["appid"]}'])
            break
        elif key == 'c':
            break


if __name__ == "__main__":
    main()
