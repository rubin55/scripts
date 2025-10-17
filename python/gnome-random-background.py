#!/usr/bin/env python3

import argparse
import contextlib
import cv2
import os
import json
import pathlib
import random
import subprocess
import urllib.parse

home = pathlib.Path.home()
backgrounds = home / '.local/share/backgrounds'


def classify_image(image_path, threshold=127):
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    mean_intensity = img.mean()
    return 'light' if mean_intensity > threshold else 'dark'


def classify_directory(directory, reinit=False):
    light, dark = [], []
    cache_file = directory / 'classification-cache.json'

    # If reinit=True, throw away the cache.
    if reinit:
        with contextlib.suppress(FileNotFoundError):
            print(f"gnome-random-background: Removing '{cache_file}'")
            pathlib.Path(cache_file).unlink()

    # Initialize light and dark file lists from cache.
    if os.path.exists(cache_file):
        with open(cache_file, 'r') as f:
            data = json.load(f)
            light = data.get('light', [])
            dark = data.get('dark', [])

    # Iterate over elements in directory and classify.
    for file_name in os.listdir(directory):
        if file_name.lower().endswith(('.png', '.jpg')):
            path = os.path.join(directory, file_name)
            abs_path = os.path.abspath(path)
            encoded_path = urllib.parse.quote(abs_path)
            file_url = f"file://{encoded_path}"

            if file_url in light:
                classification = 'light'
            elif file_url in dark:
                classification = 'dark'
            else:
                classification = classify_image(path)
                print(f"gnome-random-background: Classifying '{file_name}' as '{classification}'")
                if classification == 'light':
                    light.append(file_url)
                elif classification == 'dark':
                    dark.append(file_url)

    # Write light and dark lists to cache.
    with open(cache_file, 'w') as f:
        json.dump({'light': light, 'dark': dark}, f, indent=2)

    return light, dark


def set(mode, urls):
    if mode == 'light':
        target = 'picture-uri'
    elif mode == 'dark':
        target = 'picture-uri-dark'

    file_url = random.choice(urls)
    file_name = pathlib.Path(urllib.parse.unquote(urllib.parse.urlparse(file_url).path)).name
    print(f"gnome-random-background: Setting {mode} background to '{file_name}'")
    subprocess.run(['gsettings', 'set', 'org.gnome.desktop.background',
                    target, file_url], capture_output=False)


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest='command', required=True)

    # Light command
    light_parser = subparsers.add_parser('light')
    light_parser.set_defaults(light=True, dark=False)

    # Dark command
    dark_parser = subparsers.add_parser('dark')
    dark_parser.set_defaults(light=False, dark=True)

    # Both command
    both_parser = subparsers.add_parser('both')
    both_parser.set_defaults(light=True, dark=True)

    # Reclassify command
    reclassify_parser = subparsers.add_parser('reclassify')
    reclassify_parser.set_defaults(light=False, dark=False, reclassify=True)

    args = parser.parse_args()

    light, dark = [], []
    if hasattr(args, 'reclassify'):
        light, dark = classify_directory(backgrounds, reinit=True)
    else:
        light, dark = classify_directory(backgrounds)

    if args.light:
        set('light', light)

    if args.dark:
        set('dark', dark)


if __name__ == "__main__":
    main()
