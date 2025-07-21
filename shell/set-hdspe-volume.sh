#!/bin/bash

# Example unit file which runs this after wireplumber.
#
# [Unit]
# After=wireplumber.service
# Description=Set default HDSPE output volume to 25%
#
# [Service]
# ExecStart=/where/i/keep/my/scripts/set-hdspe-volume.sh 25%
# Type=OneShot
#
# [Install]
# WantedBy=graphical-session.target

# Ensure a *single* percentage sign is appended.
function append_percentage() {
    local v="$1"
    v="${v%\%*}"
    echo "${v}%"
}

# Get value from first argument or 25,
# ensure single percentage sign appended.
v=$(append_percentage "${1:-25}")

# We're assuming a RME HDSPe AIO Pro
# here, which has 16 output channels.
amixer -c0 -sq <<-EOF
    set Chn,1 "$v"
    set Chn,2 "$v"
    set Chn,3 "$v"
    set Chn,4 "$v"
    set Chn,5 "$v"
    set Chn,6 "$v"
    set Chn,7 "$v"
    set Chn,8 "$v"
    set Chn,9 "$v"
    set Chn,10 "$v"
    set Chn,11 "$v"
    set Chn,12 "$v"
    set Chn,13 "$v"
    set Chn,14 "$v"
    set Chn,15 "$v"
    set Chn,16 "$v"
EOF
