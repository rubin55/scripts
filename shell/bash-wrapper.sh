#!/bin/bash

# Source scripts in ~/.profile.d if exists.
if [ "$BASH_PROFILE_INITIALIZED" != "true" ]; then
    if [ -d ~/.profile.d -o -h ~/.profile.d ]; then
        for s in ~/.profile.d/*.sh; do
            source $s
        done
    fi
    export BASH_PROFILE_INITIALIZED=true
fi

exec "$@"
