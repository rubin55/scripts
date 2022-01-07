#!/bin/bash

platform=$(uname -s | tr '[:upper:]' '[:lower:]')

# But if it's WSL..
if [[ "$(uname -r)" =~ "Microsoft" ]]; then
    platform=windows
fi

case "$platform" in
    darwin)
    vi=/Applications/MacVim.app/Contents/bin/vim
    ;;
    bsd|gnu/linux|linux|unix)
    vi=/usr/bin/vim
    ;;
    windows)
    #vi=gvim.exe
    vi=/usr/bin/vim
    ;;
    *)
    echo "Unknown platform \"$platform\"."
esac

running=$(ps x| grep -wi $vi | grep -v grep)

vserver=$($vi --version | grep -w '+clientserver')


if [ ! -z "$vserver" -a -z "$running" ]; then
    # Starting new vim server to open $@..
    $vi --servername VIM "$@"
elif [ ! -z "$vserver" -a ! -z "$running" ]; then
    if [ -z "$@" ]; then
        # Focusing already-running vim..
        osascript -e 'activate application "MacVim"'
    else
        # Opening $@ on running vim server..
        $vi --servername VIM --remote "$@"
    fi
else
    # Vim client/server mode not supported, opening $@ directly..
    $vi "$@"
fi

