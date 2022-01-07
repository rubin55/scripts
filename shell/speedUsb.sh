#!/bin/bash -i

if [ $1 ]; then
	SLEEP=$1;
else
	SLEEP=1;
fi

PREV_VALUE_IN=`cat /tmp/counterUsbIN`
PREV_VALUE_OUT=`cat /tmp/counterUsbOUT`
LINECOUNT=$(tput lines);
while [ 1 ]; do

	if [ $LINECOUNT -ge $(tput lines) ]; then
		printf "%7s %7s \n" "IN" "OUT"
		LINECOUNT=2;
	else
		(( LINECOUNT++ ))
	fi

	sleep $SLEEP
	LAST_VALUE_IN=`cat /tmp/counterUsbIN`
	LAST_VALUE_OUT=`cat /tmp/counterUsbOUT`

	let VALUE_IN=${LAST_VALUE_IN}-${PREV_VALUE_IN}
	let PREV_VALUE_IN=${LAST_VALUE_IN}

	let VALUE_OUT=${LAST_VALUE_OUT}-${PREV_VALUE_OUT}
	let PREV_VALUE_OUT=${LAST_VALUE_OUT}

	mbytesSecIn=`echo "scale = 3; ${VALUE_IN}/${SLEEP}/1024/1024" | bc`
	mbytesSecOut=`echo "scale = 3; ${VALUE_OUT}/${SLEEP}/1024/1024" | bc`

	mbitsSecIn=`echo "scale = 3; ${VALUE_IN}*8/${SLEEP}/1024/1024" | bc`
	mbitsSecOut=`echo "scale = 3; ${VALUE_OUT}*8/${SLEEP}/1024/1024" | bc`

	printf "%7.3f %7.3f Mbytes/s   %7.3f %7.3f Mbits/s\n" ${mbytesSecIn} ${mbytesSecOut} ${mbitsSecIn} ${mbitsSecOut}
done
