#!/bin/sh

IFS=$'\x09'$'\x0A'$'\x0D'
WORKING_LIST="/home/rubin/Desktop/Final Rsync List.txt"
REQUESTED_USER="root"

case "$1" in
        fetch)
	for i in `cat $WORKING_LIST`; do
		echo "Host Information" > $i.txt
		ssh $REQUESTED_USER@$i \
			uname -a >> $i.txt \; \
			cat /etc/redhat-release >> $i.txt \; \
			echo \"\" >> $i.txt \; \
			echo \"Network Interfaces\" >> $i.txt \; \
			/sbin/ifconfig \| grep -A 1 \"Link encap\" \| grep -v \"\\-\\-\" >> $i.txt \; \
			echo \"\" >> $i.txt \; \
			echo \"Processor Information\" >> $i.txt \; \
			cat /proc/cpuinfo >> $i.txt \; \
			echo \"Memory Information\" >> $i.txt \; \
			cat /proc/meminfo >> $i.txt \; \
			echo \"\" >> $i.txt \; \
			echo \"Disk Information\" >> $i.txt \; \
			df -k >> $i.txt \; \
			echo \"________________________________________________________________________\" \; \
			echo \"\" >> $i.txt 
	done;
	;;
        check)
	for i in `cat $WORKING_LIST`; do
		host $i
		ssh $REQUESTED_USER@$i \
			rpm -qa \| grep -i tiv
	done;
	;;
	show)
	rm -f tmp.lst
	for i in `cat $WORKING_LIST`; do 
		cat $i.txt | grep -A 100 Filesystem | grep -v Filesystem | grep -v "\-\-" >> tmp.lst
	done;

	HDD_AVAILABLE=`cat tmp.lst | grep -v none | awk '{print $2}' | awk 'BEGIN {sum=0} {sum+=$1} END {print sum/1024/1024}'`
	printf "Aggregate Storage Available: %s GB\n" $HDD_AVAILABLE

	HDD_INUSE=`cat tmp.lst | grep -v none | awk '{print $3}' | awk 'BEGIN {sum=0} {sum+=$1} END {print sum/1024/1024}'`
	printf "Aggregate Storage In Use: %s GB\n" $HDD_INUSE

	MEM_REAL=`cat *.txt | grep MemTotal | cut -d " " -f7 | awk 'BEGIN {sum=0} {sum+=$1} END {print sum/1024/1024}'`
	printf "Aggregate Ram: %s GB\n" $MEM_REAL

	MEM_SWAP=`cat *.txt | grep SwapTotal | cut -d " " -f6 | awk 'BEGIN {sum=0} {sum+=$1} END {print sum/1024/1024}'`
	printf "Aggregate Swap: %s GB\n" $MEM_SWAP

	CPU_MEM=`cat *.txt | grep "cache size" | cut -d " " -f3 | awk 'BEGIN {sum=0} {sum+=$1} END {print sum/1024}'`
	printf "Aggregate CPU Cache: %s MB\n" $CPU_MEM

	CPU_MHZ=`cat *.txt | grep "cpu MHz" | cut -d " " -f3 | awk 'BEGIN {sum=0} {sum+=$1} END {print sum}'`
	printf "Aggregate CPU Speed: %s MHz\n" $CPU_MHZ
	;;
    list)
    for i in `ls *.txt`; do cat $i | grep Linux | grep -v Red | sed "s/Linux //" | echo `cut -d " " -f 1,2`: ; cat $i | grep Red ; echo ; done;
    ;;
	clean)
	rm -f *.txt *.lst
	;;
	*)
	echo $"Usage: $0 {fetch|check|show|list|clean}"
esac
