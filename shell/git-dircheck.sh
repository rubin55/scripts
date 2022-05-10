#!/usr/bin/env bash

dir="$1"

if [ ! -d "$dir" ]; then
    echo "Please specify a directory to check."
    exit 1
fi

echo "Checking \"$dir\" recursively for git repositories."
echo "Will list those that returned an error on 'git status':"
echo ""
for i in `find "$dir" -type d -name .git`; do cd "$i/.."; git status > /dev/null ; if [ ! "$?" -eq "0" ]; then echo $i; echo ''; fi; cd - >/dev/null ; done
