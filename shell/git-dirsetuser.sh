#!/usr/bin/env bash

dir="$1"
name="$2"
email="$3"

if [[ -d "$dir" && ! -z "$name" && ! -z "$email" ]]; then
    echo "Checking \"$dir\" recursively for git repositories. "
    echo "Will set committer name and email on any repositories found "
    echo "(config user.name, user.email):"
    echo ""
    for i in `find "$dir" -type d -name .git`; do echo "Setting committer info on $i..."; cd "$i/.."; git config user.name "$name"; git config user.email "$email"; echo ""; cd - >/dev/null ; done
else
    echo "Please specify a directory to set committer for, the name of the "
    echo "committer and the committer's email address (config user.name, "
    echo "user.email)."
    echo ""
    echo "For example: $0 '/foo/bar' 'John Doe' 'john@example.com'"
    exit 1
fi

