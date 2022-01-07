#!/bin/sh

emacs="/Applications/Emacs.app/Contents/MacOS/Emacs"
emacsclient="/Applications/Emacs.app/Contents/MacOS/bin/emacsclient"
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

