#!/bin/sh

btmgmt info | awk 'BEGIN{split("1.0b 1.1 1.2 2.0 2.1 3.0 4.0 4.1 4.2 5.0 5.1 5.2 5.3",i," ")}$1=="addr"{print $2"\tBluetooth: V"i[$4+1]}'
