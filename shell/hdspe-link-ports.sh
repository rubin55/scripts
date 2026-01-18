#!/bin/bash

# This script links monitor ports $m with playback ports $p sink id $s.
# Format of arguments: monitor_port playback_port monitor_port_playbackport
# For example: hdspe-link-ports.sh AUX0 AUX4 AUX1 AUX5

# Example unit file which runs this after wireplumber:
#
# [Unit]
# After=wireplumber.service
# Description=Link monitor port(s) to playback port(s)

# [Service]
# ExecStartPre=sleep 10
# ExecStart=%h/Source/Rubin/scripts/shell/hdspe-link-ports.sh AUX0 AUX4 AUX1 AUX5
# Type=OneShot

# [Install]
# WantedBy=graphical-session.target

# Obtain the device id for the sink we want to control.
s="alsa_output.pci-0000_07_00.0.pro-output-0"

# Link monitor ports to playback ports.
printf "%s %s\n" "$@" | while read -r m p; do
  echo "Linking monitor port $m to playback port $p on sink $s"
  pw-link "$s:monitor_$m" "$s:playback_$p"
done


