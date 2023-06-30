#!/bin/bash

# Enabling/disabling wake-on-lan in NetworkManager:
# nmcli con modify eth0 802-3-ethernet.wake-on-lan magic

# For elogind, switch on $1/$2, pre/* and post/*.
# For systemd, switch on $1, pre and post.

case "$1" in
  pre)
    # Tell us about what we're doing.
    echo "Explicitly turning off and on Wake-on-LAN and unloading r8169 module.."
    # Explicitly disable wake-on-lan.
    ethtool -s eth0 wol d
    sleep 1
    # Explicitly enable wake-on-lan.
    ethtool -s eth0 wol g
    # Take eth0 down using NetworkManager.
    nmcli con down eth0
    sleep 2
    # Remove r8169 module.
    rmmod r8169
    ;;
  post)
    # Tell us about what we're doing.
    echo "Explicitly loading r8169 module and turning off and on Wake-on-LAN.."
    # Load r8169 module.
    modprobe r8169
    sleep 2
    # Re-inject/add eth0 to bridge0.
    #brctl addif bridge0 eth0
    # Explicitly disable wake-on-lan.
    ethtool -s eth0 wol d
    sleep 1
    # Explicitly enable wake-on-lan.
    ethtool -s eth0 wol g
    ;;
esac
