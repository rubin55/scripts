#!/bin/sh

IFS=$'\x09'$'\x0A'$'\x0D'
ROOT_USER=root
SOURCE_HOST="1.2.3.4"
TARGET_HOST="5.6.7.8"
SOURCE_LVMS="/tmp/lvms.source"
TARGET_LVMS="/tmp/lvms.create"

clear 

echo "This program recreates the Logical Volume groups defined on a given SOURCE host on a given TARGET host and performs a network based restore of those volumes on the TARGET. It then performs some magic to make the TARGET bootable. It assumes you have created the volumegroup(s) like on SOURCE!"

echo ""
read -s -n 1 -p "Press any key to continue . . . "; echo; clear;

echo "Obviously this program is highly dangerous. It will destroy data on a given TARGET host and haphazard tinkering with this script can do a lot of damage. DO NOT RUN THIS PROGRAM IF YOU DO NOT KNOW WHAT YOU ARE DOING!"

echo "" 
read -s -n 1 -p "Press any key to continue . . . "; echo; clear;

echo "This program works in conjunction with RIP Linux and was tested with version 2.3 (http://www.tux.org/pub/people/kent-robotti/looplinux/rip). It assumes that you have started RIP on both the SOURCE and the TARGET hosts."

echo ""
read -s -n 1 -p "Press any key to continue . . . "; echo; clear;

echo "After RIP has started on both the SOURCE and TARGET hosts, you need to configure your network interfaces (ifconfig) and turn on the sshd daemon. For sshd, just make sure to uncomment and change the PermitRootLogin and PermitEmptyPasswords options to yes in /etc/ssh/sshd_config. Then invoke /usr/sbin/sshd. Do NOT continue until you can login as root on using SSH both SOURCE and TARGET without a password (with a password will work, however you will have to type it several times)."

echo ""
read -s -n 1 -p "Press any key to continue . . . "; echo; clear;


echo "Okey, here we go.."

echo ""

echo "Fetching LVM information from SOURCE host.."
ssh $ROOT_USER@$SOURCE_HOST lvs --noheadings -a -o lv_size,name,vg_name | sed 's/^[ \t]*//' > $SOURCE_LVMS

echo "Generating LVM commands for TARGET.."
echo '#!/bin/sh' > $TARGET_LVMS
for i in `cat $SOURCE_LVMS | sed 's/\ /\ \-n\ /'`; do
        echo "lvcreate -L $i" >> $TARGET_LVMS;
done;
chmod +x $TARGET_LVMS

echo "Sending LVM creation commands to TARGET.."
scp $TARGET_LVMS $ROOT_USER@$TARGET_HOST:$TARGET_LVMS
ssh $ROOT_USER@$TARGET_HOST $TARGET_LVMS > /dev/null

echo "Activating volumes on SOURCE and TARGET.."
ssh $ROOT_USER@$SOURCE_HOST vgchange -ay
ssh $ROOT_USER@$TARGET_HOST vgchange -ay

echo "Creating filesystems on TARGET.."
for i in `cat $SOURCE_LVMS | grep -v lvol2 | cut -d " " -f 2`; do
	echo -n "Creating $i.. Please be patient: "
	ssh $ROOT_USER@$TARGET_HOST "mke2fs -q -j /dev/mapper/vg00-$i" 
	echo "done!"
done;

echo "Creating boot volume on TARGET.."
ssh $ROOT_USER@$TARGET_HOST "mke2fs -q -j /dev/cciss/c0d0p1" 
ssh $ROOT_USER@$TARGET_HOST "e2label /dev/cciss/c0d0p1 /boot" 
ssh $ROOT_USER@$TARGET_HOST mkdir -p /target/boot
ssh $ROOT_USER@$TARGET_HOST "mount /dev/cciss/c0d0p1 /target/boot" 

echo "Mounting filesystems on TARGET.."
for i in `cat $SOURCE_LVMS | grep -v lvol2 | cut -d " " -f 2`; do
	echo -n "Mounting $i.. Please be patient: "
	ssh $ROOT_USER@$TARGET_HOST mkdir -p /target/$i
	ssh $ROOT_USER@$TARGET_HOST "mount /dev/mapper/vg00-$i /target/$i" 
	echo "done!"
done;

echo "Creating SWAP on lvol2 on TARGET.."
ssh $ROOT_USER@$TARGET_HOST "mkswap /dev/mapper/vg00-lvol2"

echo "Creating dump fetcher.."
echo "#!/bin/sh" > /tmp/lvms.fetcher
echo "echo Working on: boot.." >> /tmp/lvms.fetcher
echo "cd /target/boot" >> /tmp/lvms.fetcher
echo "ssh $SOURCE_HOST 'dump -0 -f - /dev/cciss/c0d0p1' | restore -r -f -" >> /tmp/lvms.fetcher
for i in `cat $SOURCE_LVMS | grep -v lvol2 | cut -d " " -f 2`; do
	echo "echo Working on: $i.." >> /tmp/lvms.fetcher
	echo "cd /target/$i" >> /tmp/lvms.fetcher
	echo "ssh $SOURCE_HOST 'dump -0 -f - /dev/mapper/vg00-$i' | restore -r -f -" >> /tmp/lvms.fetcher
done;
chmod +x /tmp/lvms.fetcher
scp /tmp/lvms.fetcher $ROOT_USER@$TARGET_HOST:/tmp/lvms.fetcher

echo "Remote invocation of dump fetcher on TARGET.."
ssh $ROOT_USER@$TARGET_HOST /tmp/lvms.fetcher

echo "Installing GRUB on TARGET.."
ssh $ROOT_USER@$TARGET_HOST 'grub-install --root-directory=/target/boot /dev/cciss/c0d0'

echo "Removing LVM cache from TARGET.."
ssh $ROOT_USER@$TARGET_HOST 'rm /target/lvol3/etc/lvm/.cache'
ssh $ROOT_USER@$TARGET_HOST 'vgck'
ssh $ROOT_USER@$TARGET_HOST 'vgscan --verbose'

echo "Deploying custom updates to /root on TARGET.."
rsync -av updates/root/ $ROOT_USER@$TARGET_HOST:/target/lvol3/root/

