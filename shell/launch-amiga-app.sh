#!/usr/bin/env bash

# Check for arguments.
if [[ -z "$1" ]]; then
    echo "Usage: $(basename $0) <path to app, Amiga style>"
    echo "For example: $(basename $0) Games:RickDangerous/RickDangerous"
    exit 1
fi

# A few environment variables.
fsuaeExecutable="fs-uae"
fsuaeHome="$HOME/Documents/FS-UAE"
fsuaeConfiguration="$fsuaeHome/Configurations/Rubin's A1200 (PAL, HiRes).fs-uae"
systemDiskLocation="$fsuaeHome/Hard Directories/System"
startupSequenceTemplate="$systemDiskLocation/S/startup-sequence.wbrun"

# Write custom startup-sequence using startup-sequence template.
cat "$startupSequenceTemplate" | python -c "from __future__ import print_function;import re,sys; print(sys.stdin.read().replace(sys.argv[1], sys.argv[2]))" "\$APP" "$1" "0" > "$systemDiskLocation/S/startup-sequence"

# Use Dos2Unix to make sure we have no \r (carriage return) in our startup sequence.
dos2unix "$systemDiskLocation/S/startup-sequence"

# Execute FS-UAE with specified configuration.
"$fsuaeExecutable" "$fsuaeConfiguration"
