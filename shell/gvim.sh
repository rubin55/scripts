#!/usr/bin/env bash

# Workaround non-working wayland mode.
export GDK_BACKEND='x11'

# Get the current platform in lowercase.
platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

# But if it's WSL, rewrite to 'windows'.
if [[ "$(uname -r)" =~ 'Microsoft' ]]; then
    platform='windows'
fi

# Set gvim variable based on platform.
case "$platform" in
    darwin)
    gvim='/Applications/MacVim.app/Contents/bin/gvim'
    ;;
    bsd|gnu/linux|linux|unix)
    gvim='/usr/bin/gvim'
    ;;
    windows)
    gvim='/mnt/c/Program Files/Vim/vim82/gvim.exe'
    ;;
    *)
    echo "Unknown platform \"$platform\"."
esac

# Contains a pid when gvim is running.
running="$(pgrep -f "$gvim")"

# Contains a non-empty string when gvim supports client/server mode.
vserver="$("$gvim" --version | grep -w '+clientserver')"

# Vim supports client/server mode and is *not* running.
if [ ! -z "$vserver" -a -z "$running" ]; then
    # Starting new gvim to open $@..
    "$gvim" --servername VIM -f "$@"
# Vim supports client/server mode and *is* running.
elif [ ! -z "$vserver" -a ! -z "$running" ]; then
    # Check if any arguments were given.
    if [ -z "$@" ]; then
        # No arguments, focusing running gvim..
        xdotool windowactivate "$(xdotool search --name VIM | tail -n 1)"
    else
        # Opening $@ on running gvim..
        "$gvim" --servername VIM --remote-wait "$@"
    fi
# Vim does *not* support client/server mode.
else
    # Opening $@ directly..
    "$gvim" -f "$@"
fi
