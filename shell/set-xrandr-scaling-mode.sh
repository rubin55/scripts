#!/bin/sh

# Only run on X11 sessions.
if [ "$XDG_SESSION_TYPE" != "x11" ]; then
    echo "Running session is not x11, but "$XDG_SESSION_TYPE". Exiting.."
    exit 1
fi

mode="Full Aspect"
filter="nearest"

for output in $(xrandr --prop | grep -E -o -i "^[A-Z\-]+-[0-9]+"); do
    echo "$output:\tSetting scaling mode to \"$mode\" using \"$filter\" filter.."
    xrandr --output "$output" --set "scaling mode" "$filter" --filter "$filter"
done
