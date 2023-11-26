#!/usr/bin/env bash

dir="$1"

if [ ! -d "$dir" ]; then
    echo "Please specify a directory to set to ignore file mode (config core.fileMode false)."
    exit 1
fi

echo "Checking \"$dir\" recursively for git repositories."
echo "Will set found repositories to ignore file mode (config core.fileMode false) those found:"
echo ""
for i in `find "$dir" -type d -name .git`; do echo "Setting ignore file mode on $i..."; cd "$i/.."; git config core.fileMode false; echo ""; cd - >/dev/null ; done
