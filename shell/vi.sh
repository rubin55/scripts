#!/bin/bash

platform=$(uname -s | tr '[:upper:]' '[:lower:]')

# But if it's WSL..
if [[ "$(uname -r)" =~ "Microsoft" ]]; then
    platform=windows
fi

case "$platform" in
    darwin)
    vi=/Applications/MacVim.app/Contents/bin/gvim
    ;;
    bsd|gnu/linux|linux|unix)
    vi=gvim
    ;;
    windows)
    vi=gvim.exe
    ;;
    *)
    echo "Unknown platform \"$platform\"."
esac

running=$(ps x| grep -wi $vi | grep -v grep)

vserver=$($vi --version | grep -w '+clientserver')


if [ ! -z "$vserver" -a -z "$running" ]; then
    # Starting new vim server to open $@..
    $vi --servername VIM -f "$@"
elif [ ! -z "$vserver" -a ! -z "$running" ]; then
    if [ -z "$@" ]; then
        # Focusing already-running vim..
        xdotool windowactivate `xdotool search --name VIM | tail -n 1`
    else
        # Opening $@ on running vim server..
        $vi --servername VIM --remote-wait "$@"
    fi
else
    # Vim client/server mode not supported, opening $@ directly..
    $vi -f "$@"
fi

