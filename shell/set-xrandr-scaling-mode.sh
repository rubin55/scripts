#!/bin/sh

mode="Full Aspect"
filter="nearest"

for output in $(xrandr --prop | grep -E -o -i "^[A-Z\-]+-[0-9]+"); do
    echo "$output:\tSetting scaling mode to \"$mode\" using \"$filter\" filter.."
    xrandr --output "$output" --set "scaling mode" "$filter" --filter "$filter"
done
