#!/bin/bash

# This script sets a volume $v of a sink $s with id $i. Additionally, it works
# around weird pipewire / wireplumber behavior, where commandline tools like
# wpctl do nothing when the pipewire graph has never played anything before,
# by creating a silent flac file $f from a base64 string $b which is then fed
# to pw-play at explicitly-set 0 volume.

# Example unit file which runs this after wireplumber:
#
# [Unit]
# After=wireplumber.service
# Description=Lower HDSPe Volume Default

# [Service]
# ExecStartPre=sleep 10
# ExecStart=%h/Source/Rubin/scripts/shell/hdspe-set-volume.sh
# Type=OneShot

# [Install]
# WantedBy=graphical-session.target

# Ensure a *single* percentage sign is appended.
function append_percentage() {
    local v="$1"
    v="${v%\%*}"
    echo "${v}%"
}

# Base64 string with one second of 192kHz silent stereo.
b="ZkxhQwAAACIQABAAAAAQAAASLuADcAAC7gBUq0XtMpyfC/3v/250dTRZhAAAKCAAAAByZWZlcmVuY2UgbGliRkxBQyAxLjUuMCAyMDI1MDIxMQAAAAD/+MMcABEAAAAAAAAAAIDC//jDHAEWAAAAAAAAAADz9v/4wxwCHwAAAAAAAAAAZqr/+MMcAxgAAAAAAAAAABWe//jDHAQNAAAAAAAAAADMF//4wxwFCgAAAAAAAAAAvyP/+MMcBgMAAAAAAAAAACp///jDHAcEAAAAAAAAAABZS//4wxwIKQAAAAAAAAAAGWj/+MMcCS4AAAAAAAAAAGpc//jDHAonAAAAAAAAAAD/AP/4wxwLIAAAAAAAAAAAjDT/+MMcDDUAAAAAAAAAAFW9//jDHA0yAAAAAAAAAAAmif/4wxwOOwAAAAAAAAAAs9X/+MMcDzwAAAAAAAAAAMDh//jDHBBhAAAAAAAAAAAzk//4wxwRZgAAAAAAAAAAQKf/+MMcEm8AAAAAAAAAANX7//jDHBNoAAAAAAAAAACmz//4wxwUfQAAAAAAAAAAf0b/+MMcFXoAAAAAAAAAAAxy//jDHBZzAAAAAAAAAACZLv/4wxwXdAAAAAAAAAAA6hr/+MMcGFkAAAAAAAAAAKo5//jDHBleAAAAAAAAAADZDf/4wxwaVwAAAAAAAAAATFH/+MMcG1AAAAAAAAAAAD9l//jDHBxFAAAAAAAAAADm7P/4wxwdQgAAAAAAAAAAldj/+MMcHksAAAAAAAAAAACE//jDHB9MAAAAAAAAAABzsP/4wxwg8QAAAAAAAAAAZmX/+MMcIfYAAAAAAAAAABVR//jDHCL/AAAAAAAAAACADf/4wxwj+AAAAAAAAAAA8zn/+MMcJO0AAAAAAAAAACqw//jDHCXqAAAAAAAAAABZhP/4wxwm4wAAAAAAAAAAzNj/+MMcJ+QAAAAAAAAAAL/s//jDHCjJAAAAAAAAAAD/z//4wxwpzgAAAAAAAAAAjPv/+MMcKscAAAAAAAAAABmn//jDHCvAAAAAAAAAAABqk//4wxws1QAAAAAAAAAAsxr/+MMcLdIAAAAAAAAAAMAu//hzHC4N//YAAAAAAAAAAK++"

# Create silence.flac from base64 above.
f="/tmp/silence.flac"
echo "$b" | base64 -d - > "$f"


# First play a one-second 192kHz audio file silently.
# for some reason command-line control of pipewire and
# wireplumber does not work if this is not done first.
echo "Playing $f at 0% volume.."
pw-play --volume 0 "$f"

# Get value from first argument or 25,
# ensure single percentage sign appended.
v=$(append_percentage "${1:-25}")

# Obtain the device id for the sink we want to control.
s="alsa_output.pci-0000_07_00.0.pro-output-0"
i="$(pw-cli info "$s" | head -n 1 | awk '{print $2}')"

# Set volume on sink with id $i.
echo "Setting volume to $v on device with id $i.."
wpctl set-volume "$i" "$v"

# Alternative way using ALSA.
# amixer -c0 -sq <<-EOF
#     set Chn,1 "$v"
#     set Chn,2 "$v"
#     set Chn,3 "$v"
#     set Chn,4 "$v"
#     set Chn,5 "$v"
#     set Chn,6 "$v"
#     set Chn,7 "$v"
#     set Chn,8 "$v"
#     set Chn,9 "$v"
#     set Chn,10 "$v"
#     set Chn,11 "$v"
#     set Chn,12 "$v"
#     set Chn,13 "$v"
#     set Chn,14 "$v"
#     set Chn,15 "$v"
#     set Chn,16 "$v"
# EOF
