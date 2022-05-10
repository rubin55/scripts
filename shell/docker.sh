#!/bin/bash

exe=$(which docker)

if [ "$1" == "build" ]; then
    echo "Build argument passed, rewriting command to:"
    cmd="$exe build --build-arg http_proxy=$http_proxy --build-arg https_proxy=$http_proxy --build-arg HTTP_PROXY=$http_proxy --build-arg HTTPS_PROXY=$http_proxy $2 $3 $4 $5 $6 $7 $8 $9"
    echo "$cmd"
    sleep 4
    eval "$cmd"
else
    cmd="$exe $*"
    eval "$cmd"
fi
