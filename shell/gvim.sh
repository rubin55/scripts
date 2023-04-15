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
    vim='/Applications/MacVim.app/Contents/bin/vim'
    gvim='/Applications/MacVim.app/Contents/bin/gvim'
    ;;
    bsd|gnu/linux|linux|unix)
    vim='/usr/bin/vim'
    gvim='/usr/bin/gvim'
    ;;
    windows)
    vim='vim.exe'
    gvim='gvim.exe'
    ;;
    *)
    echo "Unknown platform \"$platform\"."
esac

# Check if gvim is running.
case "$platform" in
    darwin)
    running="$(pgrep -f "$gvim")"
    ;;
    bsd|gnu/linux|linux|unix)
    running="$(pgrep -f "$gvim")"
    ;;
    windows)
    running="$(tasklist.exe | grep gvim.exe | awk '{print $2}')"
    ;;
    *)
    echo "Unknown platform \"$platform\"."
esac

# Contains a non-empty string when gvim supports client/server mode.
vserver="$("$vim" --version | grep -w '+clientserver')"

# Vim supports client/server mode and is *not* running.
if [ ! -z "$vserver" -a -z "$running" ]; then
    # Check if any arguments were given.
    if [ -z "$@" ]; then
        # Starting new gvim ..
        "$gvim" --servername VIM
    else
        # Starting new gvim to open $@..
        "$gvim" --servername VIM -f "$@"
    fi
# Vim supports client/server mode and *is* running.
elif [ ! -z "$vserver" -a ! -z "$running" ]; then
    # Check if any arguments were given.
    if [ -z "$@" ]; then
        # No arguments, focusing running gvim..
        case "$platform" in
            darwin)
            # No focus necessary on Darwin.
            ;;
            bsd|gnu/linux|linux|unix)
            xdotool windowactivate "$(xdotool search --name VIM | tail -n 1)"
            ;;
            windows)
            # No focus necessary on Windows.
            ;;
            *)
            echo "Unknown platform \"$platform\"."
        esac

    else
        # Opening $@ on running gvim..
        "$gvim" --servername VIM --remote-wait "$@"
    fi
# Vim does *not* support client/server mode.
else
    # Opening $@ directly..
    "$gvim" -f "$@"
fi
