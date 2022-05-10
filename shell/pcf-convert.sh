#!/bin/bash
#

if [ -z "$1" ] || [ -z "$2" ]; then
	echo "Usage: $0 <path to PCFs> <output dir>"
	exit 1
fi

if [ ! -d "$1" ]; then
	echo "Path to PCFs does not exist."
	exit 1
fi

if [ ! -d "$2" ]; then
	echo "Path to output directory does not exist."
	exit 1
fi

IFS=$'\n'

for file in $(ls $1/*.pcf); do

	profile=$(basename $file .pcf)
	profile=$(echo $profile | sed -e 's/ /-/g' | tr A-Z a-z)

	echo "IPSec gateway $(grep ^Host $file | awk -F= '{print $2}')" > $2/$profile.conf
	echo "IPSec ID $(grep ^GroupName $file | awk -F= '{print $2}')" >> $2/$profile.conf

	grouppwd=$(grep ^enc_GroupPwd $file | awk -F= '{print $2}')
	grouppwd=$(echo $grouppwd | sed -e 's/\r//g')
	if [ ! -z "$grouppwd" ]; then
		echo "IPSec secret $(./cisco-decrypt $grouppwd)" >> $2/$profile.conf
	fi

	echo "Converted $(basename $file .pcf)"
done
