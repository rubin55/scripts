#!/bin/sh

if [ ! "$1" ]; then
    echo "Please specify input file"
    exit 1
fi

cat "$1" | awk '{ printf "%s", $0 }'
