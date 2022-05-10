#!/usr/bin/env bash

dir="$1"

if [ ! -d "$dir" ]; then
    echo "Please specify a directory for which to show branches."
    exit 1
fi

echo "Checking \"$dir\" recursively for git repositories."
echo "Will show branches for those found:"
echo ""
for i in `find "$dir" -type d -name .git`; do echo "Showing branches for $i..."; cd "$i/.."; git branch -a; echo ""; cd - >/dev/null ; done
