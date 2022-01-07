#!/bin/sh

case "$1" in
    connect)
    rfcomm connect rfcomm0 &
    sleep 2
    wvdial rfcomm0 &
    sleep 8
    cp /var/run/ppp/resolv.conf /etc/resolv.conf
    ;;
    disconnect)
    killall wvdial
    sleep 4
    rfcomm release rfcomm0
    ;;
    *)
    echo $"Usage: $0 {connect|disconnect}"
    exit 1
esac

