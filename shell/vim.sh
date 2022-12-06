#!/usr/bin/env bash

# Workaround non-working wayland mode.
export GDK_BACKEND='x11'

# Get the current platform in lowercase.
platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

# But if it's WSL, rewrite to 'windows'.
if [[ "$(uname -r)" =~ 'Microsoft' ]]; then
    platform='windows'
fi

# Set vim variable based on platform.
case "$platform" in
    darwin)
    vim='/Applications/MacVim.app/Contents/bin/vim'
    ;;
    bsd|gnu/linux|linux|unix)
    vim='/usr/bin/vim'
    ;;
    windows)
    vim='/mnt/c/Program Files/Vim/vim82/vim.exe'
    ;;
    *)
    echo "Unknown platform \"$platform\"."
esac

# Contains a pid when vim is running.
running="$(pgrep -f "$vim")"

# Contains a non-empty string when vim supports client/server mode.
vserver="$("$vim" --version | grep -w '+clientserver')"

# Vim supports client/server mode and is *not* running.
if [ ! -z "$vserver" -a -z "$running" ]; then
    # Starting new vim to open $@..
    "$vim" --servername VIM -f "$@"
# Vim supports client/server mode and *is* running.
elif [ ! -z "$vserver" -a ! -z "$running" ]; then
    # Check if any arguments were given.
    if [ -z "$@" ]; then
        # No arguments, focusing running vim..
        xdotool windowactivate "$(xdotool search --name VIM | tail -n 1)"
    else
        # Opening $@ on running vim..
        "$vim" --servername VIM --remote-wait "$@"
    fi
# Vim does *not* support client/server mode.
else
    # Opening $@ directly..
    "$vim" -f "$@"
fi
