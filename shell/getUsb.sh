#!/bin/bash

COUNTER=0;
# first get USB devices
IFS=$'\n'
USBDEVICES=$( lsusb | grep -v "0000:0000" | grep -iv "hub" )
CHOOSED_DEVICE=$(zenity --list  --width=700 --height=500 --title "Connected USB devices" --column="Devices" ${USBDEVICES[@]})
unset IFS

echo ${CHOOSED_DEVICE} 
echo ${CHOOSED_DEVICE} | cut -d: -f 1 | read 

BUS=`echo ${CHOOSED_DEVICE} | cut -d: -f 1 | cut -d\  -f 2`
DEVICE=`echo ${CHOOSED_DEVICE} | cut -d: -f 1 | cut -d\  -f 4`

let BUS=$BUS+0

echo $BUS
echo $DEVICE

# create data to pipe
let totalIN=0;
let totalOUT=0;

echo "usbmon -i ${BUS} | grep "C Bo:${BUS}:${DEVICE}" ";

usbmon -i ${BUS} | grep "C B" | grep "${BUS}:${DEVICE}" | while read  garb1 garb2 garb3 status garb5 value finalGarb; do 
	if [[ $status =~ "Bo" ]]; then
		let totalIN=$totalIN+$value
		echo $totalIN > /tmp/counterUsbIN
	elif [[ $status =~ "Bi" ]]; then
		let totalOUT=$totalOUT+$value
		echo $totalOUT > /tmp/counterUsbOUT
	else
		echo "discarded"
		continue;
	fi

done

