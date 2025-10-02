#!/bin/bash

# Source scripts in ~/.profile.d if exists.
if [ -d ~/.profile.d -o -h ~/.profile.d ]; then
    for s in ~/.profile.d/*.sh; do
        source $s
    done
fi

"$@"
