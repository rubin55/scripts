#!/bin/sh
#
# List of parameters passed through environment
#* reason                       -- why this script was called, one of: pre-init connect disconnect reconnect attempt-reconnect
#* VPNGATEWAY                   -- vpn gateway address (always present)
#* TUNDEV                       -- tunnel device (always present)
#* INTERNAL_IP4_ADDRESS         -- address (always present)
#* INTERNAL_IP4_MTU             -- mtu (often unset)
#* INTERNAL_IP4_NETMASK         -- netmask (often unset)
#* INTERNAL_IP4_NETMASKLEN      -- netmask length (often unset)
#* INTERNAL_IP4_NETADDR         -- address of network (only present if netmask is set)
#* INTERNAL_IP4_DNS             -- list of dns servers
#* INTERNAL_IP4_NBNS            -- list of wins servers
#* INTERNAL_IP6_ADDRESS         -- IPv6 address
#* INTERNAL_IP6_NETMASK         -- IPv6 netmask
#* INTERNAL_IP6_DNS             -- IPv6 list of dns servers
#* CISCO_DEF_DOMAIN             -- default domain name
#* CISCO_BANNER                 -- banner from server
#* CISCO_SPLIT_INC              -- number of networks in split-network-list
#* CISCO_SPLIT_INC_%d_ADDR      -- network address
#* CISCO_SPLIT_INC_%d_MASK      -- subnet mask (for example: 255.255.255.0)
#* CISCO_SPLIT_INC_%d_MASKLEN   -- subnet masklen (for example: 24)
#* CISCO_SPLIT_INC_%d_PROTOCOL  -- protocol (often just 0)
#* CISCO_SPLIT_INC_%d_SPORT     -- source port (often just 0)
#* CISCO_SPLIT_INC_%d_DPORT     -- destination port (often just 0)
#* CISCO_IPV6_SPLIT_INC         -- number of networks in IPv6 split-network-list
#* CISCO_IPV6_SPLIT_INC_%d_ADDR -- IPv6 network address
#* CISCO_IPV6_SPLIT_INC_$%d_MASKLEN -- IPv6 subnet masklen

#### Main

if [ -z "$reason" ]; then
	echo "This script must be called from a vpnc-script supporting VPN client" 1>&2
	exit 1
fi

case "$reason" in
	pre-init)
        # Do this first.
		;;
	connect)
        # Right after connect.
        echo "Writing env.out"
        env > /tmp/env.out

		;;
	disconnect)
        # After disconnect.
		;;
	attempt-reconnect)
		# Invoked before each attempt to re-establish the session.
		# If the underlying physical connection changed, we might
		# be left with a route to the VPN server through the VPN
		# itself, which would need to be fixed.
		;;
	reconnect)
		# After successfully re-establishing the session.
		;;
	*)
		echo "Unknown reason '$reason'. Maybe this vpnc-script is out of date?" 1>&2
		exit 1
		;;
esac

exit 0

