#!/usr/bin/env python3 

import cv2
import os
import json
import random
import shutil
import subprocess
import time
import urllib.parse

def classify_image(image_path, threshold=127):
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    mean_intensity = img.mean()
    return 'light' if mean_intensity > threshold else 'dark'


directory = '/home/rubin/.local/share/backgrounds'
cache_file = directory + '/classification-cache.json'
light = []
dark = []

# Load cache if exists
if os.path.exists(cache_file):
    with open(cache_file, 'r') as f:
        data = json.load(f)
        light = data.get('light', [])
        dark = data.get('dark', [])

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
            if classification == 'light':
                light.append(file_url)
            else:
                dark.append(file_url)
            print(f"Classified {file_name} as {classification}...")

# Save updated cache
with open(cache_file, 'w') as f:
    json.dump({'light': light, 'dark': dark}, f, indent=2)

# Set a random light image
if light:
    random_light = random.choice(light)
    print(f"set-random-backgrounds: Setting light background ...")
    subprocess.run(['gsettings', 'set', 'org.gnome.desktop.background', 'picture-uri', random_light], capture_output=False)

# Set a random dark image
if dark:
    random_dark = random.choice(dark)
    print(f"set-random-backgrounds: Setting dark background ...")
    subprocess.run(['gsettings', 'set', 'org.gnome.desktop.background', 'picture-uri-dark', random_dark], capture_output=False)

