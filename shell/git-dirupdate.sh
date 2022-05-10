#!/usr/bin/env bash

dir="$1"

if [ ! -d "$dir" ]; then
    echo "Please specify a directory to update (pull --all)."
    exit 1
fi

echo "Checking \"$dir\" recursively for git repositories."
echo "Will update (pull --all) those found:"
echo ""
for i in `find "$dir" -type d -name .git`; do echo "About to update $i..."; cd "$i/.."; git pull --all; echo ""; cd - >/dev/null ; done
