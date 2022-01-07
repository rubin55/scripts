#!/bin/sh

# Force 16 color mode for emacs
#export TERM=xterm-16color

# Workaround non-working wayland mode
export GDK_BACKEND=x11

running=$(pgrep -f emacs)

if [ -z "$running" ]; then
    emacs
    sleep 4
    if [ "$@" ]; then
        emacsclient "$@"
    fi
else
    if [ "$@" ]; then
        emacsclient -n "$@"
    else
        emacsclient -n
    fi
fi

