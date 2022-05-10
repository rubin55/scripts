#!/bin/sh

DOMAIN=$1
DISTRO=` cat /etc/redhat-release | cut -d " " -f 1 | cut -d "." -f 1`
RELEASE=`cat /etc/redhat-release | cut -d " " -f 3 | cut -d "." -f 1`

if [ ! $USER = root ]; then
    echo "You need root privileges to run this program."
    exit 1
fi

if [ ! -z $SUDO_USER ]; then
   echo "Hey, you're running sudo! Great!"
   SUDO_HOME=`getent passwd |grep $SUDO_USER | cut -d ":" -f 6`
   RPMMACROS=$SUDO_HOME/.rpmmacros
else
   RPMMACROS=$HOME/.rpmmacros
fi

if [ $DISTRO = CentOS ]; then 
    DISTRO=RHEL
fi

case "$1" in
	grond.org)
	TOPDIR=/net/Packaging/$DOMAIN/$DISTRO/$RELEASE
	echo "%_topdir $TOPDIR"                                                            > $RPMMACROS
    echo "%_query_all_fmt %%{name}-%%{version}-%%{release}.%%{arch}"                  >> $RPMMACROS
	echo '%debug_package %{nil}'                                                      >> $RPMMACROS
    echo '%_signature gpg'                                                            >> $RPMMACROS
    echo "%_gpg_name info@$DOMAIN"                                                    >> $RPMMACROS
    echo ''                                                                           >> $RPMMACROS
    OLD=$(cat /etc/hosts | grep `hostname -s` | awk '{print $2}' | cut -d "." -f 2,3)
    NEW=$DOMAIN
    cat /etc/hosts | sed -e "s|$OLD|$NEW|g" > /tmp/hosts.tmp
    mv /tmp/hosts.tmp /etc/hosts
    chmod 644 /etc/hosts
	;;
	openpcf.org)
	TOPDIR=/net/Packaging/$DOMAIN/$DISTRO/$RELEASE
	echo "%_topdir $TOPDIR"                                                            > $RPMMACROS
    echo "%_query_all_fmt %%{name}-%%{version}-%%{release}.%%{arch}"                  >> $RPMMACROS
	echo '%debug_package %{nil}'                                                      >> $RPMMACROS
    echo '%_signature gpg'                                                            >> $RPMMACROS
    echo "%_gpg_name info@$DOMAIN"                                                    >> $RPMMACROS
    echo ''                                                                           >> $RPMMACROS
    OLD=$(cat /etc/hosts | grep `hostname -s` | awk '{print $2}' | cut -d "." -f 2,3)
    NEW=$DOMAIN
    cat /etc/hosts | sed -e "s|$OLD|$NEW|g" > /tmp/hosts.tmp
    mv /tmp/hosts.tmp /etc/hosts
    chmod 644 /etc/hosts
	;;
	raaftech.nl)
	TOPDIR=/net/Packaging/$DOMAIN/$DISTRO/$RELEASE
	echo "%_topdir $TOPDIR"                                                            > $RPMMACROS
    echo "%_query_all_fmt %%{name}-%%{version}-%%{release}.%%{arch}"                  >> $RPMMACROS
	echo '%debug_package %{nil}'                                                      >> $RPMMACROS
    echo '%_signature gpg'                                                            >> $RPMMACROS
    echo "%_gpg_name info@$DOMAIN"                                                    >> $RPMMACROS
    echo ''                                                                           >> $RPMMACROS
    OLD=$(cat /etc/hosts | grep `hostname -s` | awk '{print $2}' | cut -d "." -f 2,3)
    NEW=$DOMAIN
    cat /etc/hosts | sed -e "s|$OLD|$NEW|g" > /tmp/hosts.tmp
    mv /tmp/hosts.tmp /etc/hosts
    chmod 644 /etc/hosts
	;;
	*)
	echo $"Usage: $0 {grond.org|openpcf.org|raaftech.nl}"
esac
    
echo "Showing /etc/hosts:"
cat /etc/hosts
echo ''

echo "Showing $RPMMACROS:"
cat $RPMMACROS
echo ''

echo "Your package directory is \"$TOPDIR\""
echo ''

