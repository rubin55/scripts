#!/bin/bash
case $1/$2 in
  pre/*)
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
  post/*)
    # Load r8169 module.
    modprobe r8169
    sleep 2
    # Re-inject/add eth0 to bridge0.
    brctl addif bridge0 eth0
    # Explicitly disable wake-on-lan.
    ethtool -s eth0 wol d
    sleep 1
    # Explicitly enable wake-on-lan.
    ethtool -s eth0 wol g
    ;;
esac
