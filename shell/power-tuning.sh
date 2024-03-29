#!/bin/bash

# Set the display to halfbright.
echo 24 > /sys/class/backlight/amdgpu_bl0/brightness

# Set a few generic power-saving options.
if [ -e '/proc/sys/vm/dirty_writeback_centisecs' ]; then
    echo '1500' > '/proc/sys/vm/dirty_writeback_centisecs'
fi
if [ -e '/proc/sys/kernel/nmi_watchdog' ]; then
    echo '0' > '/proc/sys/kernel/nmi_watchdog'
fi
if [ -e '/sys/module/snd_hda_intel/parameters/power_save' ]; then
    echo '1' > '/sys/module/snd_hda_intel/parameters/power_save'
fi

# Enable power management for network devices.
netdevs=$(ip -o l | cut -d: -f2 | grep -v lo | tr -d ' ')
for dev in $netdevs; do
    case $dev in
        eth*)
        ethtool -s $dev wol d 2> /dev/null
        ;;
        wlan*)
        iw dev wlan0 set power_save on
        ;;
	sit0@NONE)
	;;
        *)
        echo "Don\'t know what kind of device $dev is. Not setting power-saving features."
        ;;
    esac
done

# Enable power management for scsi/ahci host controllers.
hbadevs=$(ls -d /sys/class/scsi_host/host* 2>/dev/null)
for dev in $hbadevs; do
    echo 'min_power' > $dev/link_power_management_policy
done

# Enable power management for PCI devices.
pcidevs=$(ls -d /sys/bus/pci/devices/*)
for dev in $pcidevs; do
    echo auto > $dev/power/control
done

# Enable power management for USB devices.
excluded="Das Keyboard HHKB Professional Topre Realforce Convertible TKL Razer Imperator"
usbdevs=$(ls -d /sys/bus/usb/devices/*)
for dev in $usbdevs; do
    product=$(if [ -e $dev/product ]; then cat $dev/product; else echo empty; fi)

    for keyword in $excluded; do
        if [[ "$product" =~ "$keyword" ]]; then
            skip=true
        fi
    done

    if [ ! "$skip" -a -e $dev/power/control ]; then
        echo auto > $dev/power/control;
    elif [ "$product" != "empty" ]; then
        echo "Skipping power management setting for $product"
    fi

    unset skip
done

# Set cpu scheduler to ondemand.
for cpu in $(ls -d /sys/devices/system/cpu/cpu[0-9]*); do
    echo ondemand >$cpu/cpufreq/scaling_governor;
done

