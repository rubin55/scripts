#!/bin/bash

file="$1"
oldPrefix="$2"
newPrefix="$3"

if [[ -z "$file" || -z "$oldPrefix" || -z "$newPrefix" ]]; then
    echo "Usage: $0 <file> <old-prefix> <new-prefix>"
    echo ""
    echo "Can rewrite linker path for given library dependency. Use this"
    echo "with care! Use otool -L to see a list of deps for a given file"
    exit 1
fi

while read line; do
        oldPath="$(echo "$line" | sed 's|\.dylib.*$|.dylib|g')"
        newPath="${oldPath/$oldPrefix/$newPrefix}"

        echo "Changing \"$oldPath\" to \"$newPath\" in: \"$file\""
        install_name_tool -change "$oldPath" "$newPath" "$file"
done <<< "$(otool -L "$file" | grep "$oldPrefix")"
