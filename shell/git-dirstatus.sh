#!/usr/bin/env bash

dir="$1"

if [ ! -d "$dir" ]; then
    echo "Please specify a directory to check for status."
    exit 1
fi

echo "Checking \"$dir\" recursively for git repositories."
echo "Will show status output for those found:"
echo ""
for i in `find "$dir" -type d -name .git`; do echo "Showing status for $i..."; cd "$i/.."; git status; echo ""; cd - >/dev/null ; done
