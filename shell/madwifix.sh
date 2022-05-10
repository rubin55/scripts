#!/bin/bash
#
# /etc/pm/sleep.d/madwifix.sh: Woraround association bug after suspend.

madWifix() {
    echo "Removing MadWIFI modules..."
    /sbin/rmmod ath_pci ath_rate_sample ath_hal wlan_scan_sta wlan
    sleep 1
    echo "Re-inserting MadWIFI modules..."
    /sbin/modprobe ath_pci
    /sbin/modprobe wlan
    sleep 1
    echo "Re-setting Mode 3..."
    /sbin/iwpriv wlan0 mode 3
    sleep 1
}


case $1 in
    hibernate)
        echo "Hey, we are going to suspend to disk!"
        ;;
    suspend)
        echo "Oh, this time we're doing a suspend to RAM."
        ;;
    thaw)
        echo "Ah, suspend to disk is over, we are resuming!"
        madWifix
        /etc/init.d/NetworkManager restart
        ;;
    resume)
        echo "Ah, the suspend to RAM seems to be over."
        madWifix
        /etc/init.d/NetworkManager restart
        ;;
    *)  echo "Yikes, somebody is calling me totally wrong!"
        ;;
esac
