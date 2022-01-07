#!/bin/sh

user="$(echo $USER)"
if [ "$user" != root ]; then
    echo "You have to be root to run this script."
    echo ""
    exit 1
fi

case "$1" in
    on)
    /etc/init.d/iptables stop
    /sbin/iptables -F
    /sbin/iptables -t nat -F
    /sbin/iptables -t mangle -F
    /sbin/iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
    /sbin/iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    echo 1 > /proc/sys/net/ipv4/ip_forward
    ;;
    off)
    echo 0 > /proc/sys/net/ipv4/ip_forward
    /sbin/iptables -t mangle -F
    /sbin/iptables -t nat -F
    /sbin/iptables -F
    /etc/init.d/iptables start
    ;;
esac
