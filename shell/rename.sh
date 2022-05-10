#!/bin/bash

error=0

sourcePattern=$1
targetPattern=$2

if [ -z "$sourcePattern" ]; then
    echo "No source pattern specified for mass renaming files in current folder."
    error=$((error+1))
fi

if [ -z "$targetPattern" ]; then
    echo "No target pattern specified for mass renaming files in current folder."
    error=$((error+1))
fi

if [ $error -gt 0 ]; then
    echo ""
    echo "Description:"
    echo "This script will rename all files in the current folder using a source and"
    echo "target pattern specification. Source and target patterns can be specified"
    echo "as arguments to this script. The script will then rename all files that"
    echo "match the source pattern and replace the match with the target pattern."
    echo ""
    echo "Usage: $0 <sourcePattern> <targetPattern>"
    echo ""
    echo "Example: $0 '_ ' ' - '"
    echo ""
    echo "In the example above, the script will rename all files that contain the"
    echo "character sequence '_ ' (underscore and space) and replace that sequence"
    echo "with the target pattern ' - ' (space, dash and space) in the new file name."
    exit 1
fi

IFS=""
for oldFile in *; do
    newFile=$(echo $oldFile | sed s/"$sourcePattern"/"$targetPattern"/g)
    if [ "$oldFile" != "$newFile" ]; then
	mv "$oldFile" "$newFile"
    fi
done
unset IFS
