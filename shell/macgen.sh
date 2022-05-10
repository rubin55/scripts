#!/bin/bash

# macGen() - MAC Address generator.
macGen() {
    vendor_vmw="00:0C:29"
    vendor_xen="00:16:3E"
    vendor_kvm="54:52:00"
    case "$1" in
        global)
        genmac=$(dd if=/dev/urandom bs=1 count=6 2>/dev/null | od -tx1 | head -1 | cut -d' ' -f2- | awk '{ print $1":"$2":"$3":"$4":"$5":"$6 }')
        first=`echo $genmac | cut -d : -f 1`
        indec=`printf "%d" 0x$first`
        check=$(( $indec % 2 ))
        if [ ! $check -eq 0 ]; then
            newfirst=`printf "%x" $(( $indec + 1))`
            genmac=`echo $genmac | sed "s|^$first|$newfirst|"`
        fi;
        macaddr=$genmac
        ;;
        vmw)
        venmac="$vendor_vmw"
        genmac=$(dd if=/dev/urandom bs=1 count=3 2>/dev/null | od -tx1 | head -1 | cut -d' ' -f2- | awk '{ print $1":"$2":"$3 }')
        macaddr=$venmac:$genmac
        ;;
        xen)
        venmac="$vendor_xen"
        genmac=$(dd if=/dev/urandom bs=1 count=3 2>/dev/null | od -tx1 | head -1 | cut -d' ' -f2- | awk '{ print $1":"$2":"$3 }')
        macaddr=$venmac:$genmac
        ;;
        kvm)
        venmac="$vendor_kvm"
        genmac=$(dd if=/dev/urandom bs=1 count=3 2>/dev/null | od -tx1 | head -1 | cut -d' ' -f2- | awk '{ print $1":"$2":"$3 }')
        macaddr=$venmac:$genmac
        ;;
        *)
        echo "no macgen method specified. expected any of global|vmw|xen|kvm"
        exit 1
    esac
}

macGen global
echo $macaddr
