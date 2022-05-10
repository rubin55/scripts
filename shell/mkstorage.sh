#!/bin/sh

# Make sure sbin directories are on the path.
PATH=$PATH:/sbin:/usr/sbin

# Check if disktype is available.
disktype=$(which disktype)
if [ ! -x "$disktype" ]; then
    echo "You need disktype to run this script."
    exit 1
fi

# Check if sfdisk is available.
sfdisk=$(which sfdisk)
if [ ! -x "$sfdisk" ]; then
    echo "You need sfdisk to run this script."
    exit 1
fi

# Check if we're root.
user="$(echo $USER)"
if [ "$user" != root ]; then
    echo "You have to be root to run this script."
    echo ""
    exit 1
fi

# Check if a valid device was passed.
device="$1"
if [ ! -e "$device" ]; then
    echo "Usage: $0 <device> <name> <size> <type>"
    echo "Example: $0 /dev/sdb appdata 5000 ext4"
    echo ""
    exit 1
fi

name="$2"
if [ -z "$name" ]; then
    echo "Usage: $0 <device> <name> <size> <type>"
    echo "Example: $0 /dev/sdb appdata 5000 ext4"
    echo ""
    exit 1
fi

size="$3"
if [ -z "$size" ]; then
    echo "Usage: $0 <device> <name> <size> <type>"
    echo "Example: $0 /dev/sdb appdata 5000 ext4"
    echo ""
    exit 1
fi

type="$4"
if [ -z "$type" ]; then
    echo "Usage: $0 <device> <name> <size> <type>"
    echo "Example: $0 /dev/sdb appdata 5000 ext4"
    echo ""
    exit 1
fi
echo "* Checking if $device is partitioned:"
result=$($disktype $device 2> /dev/null | grep Partition)
if [ "$?" = "0" -a "$result" ]; then
    echo "  - device partitioned"
    status="partitioned"
else
    echo "  - device unpartitioned"
    status="unpartitioned"
fi
echo ""

if [ "$status" = "partitioned" ]; then 
    echo "* Checking for an unused pv:"
    result=$($sfdisk -l $device | grep $device | grep 8e | awk '{print $1}')
    if [ "$?" = "0" -a "$result" ]; then
        match=$(pvs --noheadings -o name,vg_name | grep $result | awk '{print $2}')
        if [ "$match" ]; then
            echo "  - pv $result is in use"
            status="created"
            pv=$result
            vg=$match
        else
            echo "  - pv $result is not in use"
            status="uncreated"
            pv=$result
        fi
    else
        echo "  - check failed"
        status="failed"
        exit 1
    fi
elif [ "$status" = "unpartitioned" ]; then
    echo "* Initializing $device:"
    printf %s "\
        2048,,8e
    " | sed 's/^[[:space:]]*//' > "/tmp/part.dump"
    result=$($sfdisk -qf $device -uS 2> /dev/null < /tmp/part.dump)
    if [ "$?" = "0" ]; then
        echo "  - partition table created"
        status="uncreated"
        pv=${device}1
    else
        echo "  - partition table creation failed"
        status="failed"
        exit 1
    fi
fi
echo ""

if [ "$status" = "uncreated" -a -e "$pv" ]; then 
    echo "* Creating pv on $device:"
    result=$(pvcreate $pv 2> /dev/null)
    if [ "$?" = "0" ]; then
        echo "  - pv $pv created"
        status="created"
    else
        echo "  - pv creation failed"
        status="failed"
        exit 1
    fi
    echo ""
fi

if [ "$status" = "created" -a -z "$vg" ]; then 
    echo "* Creating vg using $pv:"
    vg=data
    result=$(vgcreate $vg $pv 2> /dev/null)
    if [ "$?" = "0" ]; then
        echo "  - vg $vg created"
        status="created"
    else
        echo "  - vg creation failed"
        status="failed"
        exit 1
    fi
    echo ""
fi

echo "* Checking if vg $vg has enough space:"
result=$(vgs --units=m --noheadings -o free $vg | cut -d '.' -f 1 | sed -e 's/^[[:space:]]*//')
if [ "$size" -lt "$result" ]; then
    echo "  - vg has $result free"
    status="free"
else
    echo "  - vg has $result free ($size was requested)"
    status="failed"
    exit 1

fi
echo ""

lv=$name
echo "* Checking if lv $lv does not exist on vg $vg:"
result=$(lvs $vg --noheadings -o name | grep $lv)
if [ -z "$result" ]; then
    echo "  - lv $lv does not exist on vg $vg"
    status="free"
else
    echo "  - lv $lv exists on vg $vg"
    status="done"
fi   
echo ""

if [ "$status" = "free" ]; then
    echo "* Creating lv $lv on $vg:"
    result=$(lvcreate -n $lv -L ${size}M $vg 2> /dev/null)
    if [ "$?" = "0" ]; then
        echo "  - lv $lv created on vg $vg"
        status="free"
    else
        echo "  - lv creation failed"
        status="failed"
        exit 1
    fi
    echo ""
fi

if [ "$status" = "free" ]; then
    echo "* Creating filesystem on /dev/$vg/$lv:"
    result=$(mkfs.$type -q -j /dev/$vg/$lv 2> /dev/null)
    if [ "$?" = "0" ]; then
        echo "  - $type fs created on /dev/$vg/$lv"
        status="done"
    else
        echo "  - fs creation failed"
        status="failed"
        exit 1
    fi
    echo ""
fi

echo "* Looking for fstab entry:"
result=$(cat /etc/fstab | grep $lv)
if [ ! "$result" ]; then
    echo "  - creating entry for /dev/$vg/$lv"
    echo "" >> /etc/fstab
    echo "/dev/$vg/$lv /$lv $type acl,user_xattr 1 2" >> /etc/fstab
else
    echo "  - entry for /dev/$vg/$lv exists"
fi
echo ""

echo "* Activating mount point if necessary:"
result=$(mount | grep $lv)
if [ ! "$result" ]; then
    echo "  - mounting /dev/$vg/$lv"
    mkdir -p /$lv
    mount /$lv
else
    echo "  - /dev/$vg/$lv mounted"
fi
echo ""

if [ "$status" = "done" ]; then
    echo "Done!"
    exit 0
else
    echo "Status is $status"
    exit 1 
fi

