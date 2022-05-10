#!/usr/bin/env bash

dir="$1"

if [ ! -d "$dir" ]; then
    echo "Please specify a directory to set to enforce file mode (config core.fileMode true)."
    exit 1
fi

echo "Checking \"$dir\" recursively for git repositories."
echo "Will set found repositories to enforce file mode (config core.fileMode true) those found:"
echo ""
for i in `find "$dir" -type d -name .git`; do echo "Setting enforce file mode on $i..."; cd "$i/.."; git config core.fileMode true; echo ""; cd - >/dev/null ; done
