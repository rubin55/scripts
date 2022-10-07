#!/bin/bash

# A simple run-once helper.
function runOnce() {
    local program=$1

    if [ $(which "$program") > /dev/null 2>&1 ]; then
        running="$(ps ax | grep "$program" | grep -v grep)"
        if [ -z "$running" ]; then
            echo "Starting $@..." >> "$log" 2>&1
            $@ >> "$log" 2>&1 &
        else
            echo "Warning: $program already running, not starting." >> "$log" 2>&1
        fi
    else
        echo "Error: $program not found on path." >> "$log" 2>&1
    fi
}

# Source scripts in ~/.profile.d if exists.
if [ -d ~/.profile.d -o -h ~/.profile.d ]; then
    for s in ~/.profile.d/*.sh; do
        source $s
    done
fi

# Log output target.
log="/tmp/startup-items.out"
rm -f "$log"

# Various X11 related setup things.
echo "Doing various X11 related setup things..." >> "$log" 2>&1
xrandr --dpi 192 >> "$log" 2>&1
mkfontscale ~/.fonts >> "$log" 2>&1
mkfontdir ~/.fonts >> "$log" 2>&1
xset +fp ~/.fonts >> "$log" 2>&1
xset fp rehash >> "$log" 2>&1
xhost +local: >> "$log" 2>&1

# If we have .Xresources, merge it.
if [ -e ~/.Xresources ]; then
    echo "Merging ~/.Xresources..." >> "$log" 2>&1
    xrdb merge ~/.Xresources >> "$log" 2>&1
fi

# No baloo please.
if [ $(which balooctl 2> /dev/null) ]; then
    echo "Disabling baloo..." >> "$log" 2>&1
    balooctl disable >> "$log" 2>&1
fi

# Run various background processes.
runOnce set-xrandr-scaling-mode.sh
runOnce fix-thinkpad-trackpoint-mouse-speed.sh
runOnce pipewire
runOnce pipewire-pulse
runOnce tpmmld -d
runOnce syncthing --no-browser

