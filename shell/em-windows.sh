#!/bin/sh

emacs="$(which runemacs.exe)"
emacsclient="$(which emacsclient.exe)"
running=$(pgrep -f "$emacs")

if [ -z "$running" ]; then
    "$emacs" &
    sleep 1
    if [ "$@" ]; then
        "$emacsclient" -n "$@"
    fi
else
    if [ "$@" ]; then
        "$emacsclient" -n "$@"
    else
        osascript -e 'activate application "Emacs"'
    fi
fi

