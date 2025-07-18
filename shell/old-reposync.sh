#!/bin/sh
SERVER="somehost"
LOCALHOME="/home/rubin/Source/Packaging/rhel/"
LOCALUSER="$USER"
REMOTEHOME="/data/redhat/"
REMOTEUSER="blah"
COMMAND="`which rsync`"
ARGUMENTS="-aPH --delete"
#ARGUMENTS="--dry-run -aPH --delete"

# A space separated list of directories you may wish to 
# exclude that exist under $LOCALHOME or $REMOTEHOME
EXCLUDELIST="/*/SOURCES /*/BUILD"

rm -f /tmp/excludelist
touch /tmp/excludelist
for i in $EXCLUDELIST; do
	echo "- $i" >> /tmp/excludelist
done

# A space separated list of directories you may wish to
# explicitly include under $LOCALHOME or $REMOTEHOME
INCLUDELIST=""

rm -f /tmp/includelist
touch /tmp/includelist
for i in $INCLUDELIST; do
	echo "+ $i" >> /tmp/includelist
done
echo "- /.*" >> /tmp/includelist


case "$1" in
	fetch)
	echo "Fetching changes from server, updating local copy of your home directory."
	echo "Excluding $EXCLUDELIST"
	echo "Press CTRL-C to cancel..."
	$COMMAND $ARGUMENTS --exclude-from="/tmp/excludelist" --include-from="/tmp/includelist" $REMOTEUSER@$SERVER:$REMOTEHOME $LOCALHOME
	rm -f /tmp/excludelist /tmp/includelist
	;;
	commit)
	echo "Committing changes to server, updating remote copy of your home directory."
	echo "Excluding $EXCLUDELIST"
	echo "Press CTRL-C to cancel..."
	$COMMAND $ARGUMENTS --exclude-from="/tmp/excludelist" --include-from="/tmp/includelist" $LOCALHOME $REMOTEUSER@$SERVER:$REMOTEHOME
	rm -f /tmp/excludelist /tmp/includelist
	;;
	*)
	echo $"Usage: $0 {fetch|commit}"
	rm -f /tmp/excludelist /tmp/includelist
	exit 1
esac

