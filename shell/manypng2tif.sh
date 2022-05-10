#!/bin/sh

BASE=~/Pictures/Photos
IFS=$'\x09'$'\x0A'$'\x0D'
CONVERT='/C/Program Files (x86)/PS3 Media Server/win32/convert.exe'

echo Making tiffs
for FILE in $(find "$BASE" -type f -name *.png); do
    OUTPUT=$(echo "$FILE" | sed 's|.png|.tif|g')
    $CONVERT -verbose "$FILE" "$OUTPUT"
done
