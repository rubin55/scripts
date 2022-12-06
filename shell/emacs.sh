#!/usr/bin/env bash

# Workaround non-working wayland mode.
export GDK_BACKEND='x11'

# Get the current platform in lowercase.
platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

# But if it's WSL, rewrite to 'windows'.
if [[ "$(uname -r)" =~ 'Microsoft' ]]; then
    platform='windows'
fi

# Set emacs variable based on platform.
case "$platform" in
    darwin)
    emacs='/Applications/Emacs.app/Contents/MacOS/Emacs'
    emacsclient='/Applications/Emacs.app/Contents/MacOS/bin/emacsclient'
    ;;
    bsd|gnu/linux|linux|unix)
    emacs='/usr/bin/emacs'
    emacsclient='/usr/bin/emacsclient'
    ;;
    windows)
    emacs='/mnt/c/Program Files/Emacs/emacs28/emacs.exe'
    emacsclient='/mnt/c/Program Files/Emacs/emacs28/emacsclient.exe'
    ;;
    *)
    echo "Unknown platform \"$platform\"."
esac

# Contains a pid when emacs is running.
running="$(pgrep -f "$emacs")"

# Emacs is *not* running.
if [ -z "$running" ]; then
    # First start emacs (do make sure you have server mode configured).
    "$emacs"
    sleep 4
    # Then attach with client.
    if [ "$@" ]; then
        "$emacsclient" "$@"
    fi
# Emacs *is* running.
else
    # Check if any arguments were given.
    if [ "$@" ]; then
        # Opening $@ on running emacs..
        "$emacsclient" -n "$@"
    else
        # No arguments, focusing running emacs..
        xdotool windowactivate `xdotool search --name emacs | tail -n 1`
    fi
fi
