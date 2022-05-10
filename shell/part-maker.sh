#!/bin/sh

# Create the default system partition table if disk is uninitialized.
if [ -e /dev/sda ]; then
    printf %s "\
        1,100,83,*
        ,,8e
        ;
    " | sed 's/^[[:space:]]*//' > "/tmp/part-system.dump"
    sfdisk -q /dev/sda -uM < /tmp/part-system.dump
else
    echo "No system disk (/dev/sda) found."
    exit 1
fi;
