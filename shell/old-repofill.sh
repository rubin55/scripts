#!/bin/sh

if [ -z $1 ]; then
    echo $"Usage: $0 {grond.org|openpcf.org|raaftech.nl}"
    exit 1
else
    DOMAIN=$1
fi

DISTRO=` cat /etc/redhat-release | cut -d " " -f 1 | cut -d "." -f 1`
if [ $DISTRO = CentOS ]; then 
    DISTRO="RHEL"
fi

RELEASE=`cat /etc/redhat-release | cut -d " " -f 3 | cut -d "." -f 1`
RPM_TOPDIR="/net/Packaging/$DOMAIN/$DISTRO"
RPM_VERSIONS="$RELEASE"
RPM_ARCHS="i386 x86_64"
RPM_TOBOTH="qla-snia"
YUM_TOPDIR="/net/Repository/`echo $DOMAIN | cut -d "." -f 1`/`echo $DISTRO | tr [A-Z] [a-z]`"

if [ ! -d $RPM_TOPDIR ]; then
    echo "Source directory not found."
    echo "I was looking for: $RPM_TOPDIR"
    exit 1
fi

echo "Starting population of yum repository with additions from rpmbuild..."
for VERSION in $RPM_VERSIONS; do
	for ARCH in $RPM_ARCHS; do
        mkdir -p $YUM_TOPDIR/$VERSION.x/os/$ARCH/RPMS
   		for PACKAGE in `ls $RPM_TOPDIR/$VERSION/RPMS/$ARCH/`; do
        	cp -vu $RPM_TOPDIR/$VERSION/RPMS/$ARCH/$PACKAGE $YUM_TOPDIR/$VERSION.x/os/$ARCH/RPMS
    	done
    	for PACKAGE in `ls $RPM_TOPDIR/$VERSION/RPMS/noarch/`; do
        	cp -vu $RPM_TOPDIR/$VERSION/RPMS/noarch/$PACKAGE $YUM_TOPDIR/$VERSION.x/os/$ARCH/RPMS
    	done
	done
done

echo "Copying i386-only packages to the x86_64 repository..."
for VERSION in $RPM_VERSIONS; do
    if [ "$RPM_TOBOTH" ]; then
	    for PARTIAL in $RPM_TOBOTH; do
            CHECK=`ls $RPM_TOPDIR/$VERSION/RPMS/i386/$PARTIAL* 2> /dev/null`
            if [ ! -z $CHECK ]; then
                echo "Found $PARTIAL, copying to both repositories..."
    	        cp -vu $RPM_TOPDIR/$VERSION/RPMS/i386/$PARTIAL* $YUM_TOPDIR/$VERSION.x/os/x86_64/RPMS
            fi
	    done
    fi;
done

echo "Correcting permissions and ownerships..."
find $YUM_TOPDIR -type d -exec chmod 755 {} \;
find $YUM_TOPDIR -type f -exec chmod 644 {} \;


echo "Rebuilding repository metadata..."
for VERSION in $RPM_VERSIONS; do
	for ARCH in $RPM_ARCHS; do
    	cd $YUM_TOPDIR/$VERSION.x/os/$ARCH
        if [ $VERSION = 4 ];then
            echo "Release $VERSION detected, need to clean up repodata first..."
            rm -rf repodata
    	    createrepo --verbose .
        else
            echo "Release $VERSION detected, using update feature..."
    	    createrepo --verbose --update .
        fi;
    	cd -
	done
done

echo "Showing repository contents..."
ls $YUM_TOPDIR/*/os/*/RPMS
