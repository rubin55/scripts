#!/usr/bin/env python

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


def read_acf(acffile: str) -> dict:
    with open(acffile, 'r') as f:
        content = f.read()
    tokens = tokenize(content)
    result, _ = parse(tokens, 0)
    return result


def get_character():
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setcbreak(fd)
        return sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)


steam_dir = Path.home() / "Steam"
acf_files = glob.glob(str(steam_dir / "steamapps" / "appmanifest_*.acf"))

while True:
    acf_file = random.choice(acf_files)
    app_state = read_acf(acf_file)["AppState"]
    app_id = app_state["appid"]
    name = app_state["name"]

    print(f'{name} (y/n/c) ', end='', flush=True)
    key = get_character()
    print(key)
    if key == 'y':
        subprocess.Popen(["steam", f"steam://rungameid/{app_id}"])
        break
    elif key == 'c':
        break
