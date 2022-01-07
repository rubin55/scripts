#!/usr/bin/env bash

dirName="$1"

if [ -d "${dirName}" -a -e "${dirName}/game.Slave" ]; then
    dirSize="$(du -sk $1)"
    hdfSize=$(echo ${dirSize} | awk '{print int($1*1.25)}')
    xdftool -f "${dirName}.hdf" pack ${dirName} size=${hdfSize}K
    gzip -c "${dirName}.hdf" > "${dirName}.hdz"
else
    echo "Usage: $0 <dirName>"
    echo "Notes: <dirName> needs to contain a game.Slave file."
    exit 1
fi
