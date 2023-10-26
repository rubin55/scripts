#!/bin/sh

DISCONF=hpux-toggleservices.conf

if [ ! -e $DISCONF ] ; then
	print "Configuration file not found, exiting..."
	exit 1
fi

if [ ! $# -eq 1 ] ; then
	print "Usage: $0 disable|enable"
	exit 1
fi

case $1 in
	disable)
	for line in `egrep -v "^#|^$" $DISCONF | sed -e 's/ //g'`; do
		RUNLEVEL=`print $line | cut -d: -f1`
		RCLINK=`print $line | cut -d: -f2`

		mv -i /sbin/rc${RUNLEVEL}.d/${RCLINK} /sbin/rc${RUNLEVEL}.disabled/
	done
	;;
	enable)
	for RUNLEVEL in 0 1 2 3 4 5; do
		if [ -e /sbin/rc${RUNLEVEL}.disabled/* ] ; then
			mv -i /sbin/rc${RUNLEVEL}.disabled/* /sbin/rc${RUNLEVEL}.d
		fi
	done
	;;
esac
