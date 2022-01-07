#!/bin/sh
IFS=$'\x09'$'\x0A'$'\x0D'

EVOLUTION_DIR="$HOME/.evolution"
EVOLUTION_MAIL="mail/local"
EVOLUTION="$EVOLUTION_DIR/$EVOLUTION_MAIL/"
THUNDERBIRD_DIR="$HOME/.thunderbird/Profiles/s9ojeym5.default"
THUNDERBIRD_MAIL="Mail/Local Folders"
THUNDERBIRD="$THUNDERBIRD_DIR/$THUNDERBIRD_MAIL/"
WINDOWS_DIR="/win/Documents and Settings/Rubin/Application Data/Thunderbird/Profiles/s9ojeym5.default"
WINDOWS_MAIL="Mail/Local Folders"
WINDOWS="$WINDOWS_DIR/$WINDOWS_MAIL/"

COMMAND="`which rsync`"
ARGUMENTS="-q"

# Let's go!
case "$1" in
	e2t) # Evolution -> Thunderbird
	echo "Synchronizing EVOLUTION -> THUNDERBIRD..."
	echo "Press CTRL-C to cancel..."
	for SOURCE in `find "$EVOLUTION" -type f \
		| grep -v "\.dat" \
		| grep -v "\.msf" \
		| grep -v "\.html" \
		| grep -v "\.ev-summary" \
		| grep -v "\.cmeta" \
		| grep -v "\.ibex" \
		| grep -v "Outbox" \
		| grep -v '.#evolution.sbd' \
		| sort`; 
		do 
			TARGET=`echo "$SOURCE" | sed "s|$EVOLUTION|$THUNDERBIRD|g"`
			echo "Syncing `basename "$SOURCE"`"
			"$COMMAND" "$ARGUMENTS" "$SOURCE" "$TARGET"
			# Kill the indexes. Thunderbird will regenerate them at startup.
			rm -f $TARGET.msf
	done;
	exit 0
	;;

	t2e) # Thunderbird -> Evolution
	echo "Synchronizing THUNDERBIRD -> EVOLUTION..."
	echo "Press CTRL-C to cancel..."
	for SOURCE in `find $THUNDERBIRD -type f \
		| grep -v "\.dat" \
		| grep -v "\.msf" \
		| grep -v "\.html" \
		| grep -v "Unsent" \
		| grep -v "Trash" \
		| grep -v "Junk" \
		| sort`;
		do
			TARGET=`echo "$SOURCE" | sed "s|$THUNDERBIRD|$EVOLUTION|g"`
			echo "Syncing `basename "$SOURCE"`"
			"$COMMAND" "$ARGUMENTS" "$SOURCE" "$TARGET"
			# Kill the indexes. Evolution will regenerate them at startup.
			rm -f $TARGET.cmeta
			rm -f $TARGET.ev-summary
			rm -f $TARGET.ev-summary-meta
			rm -f $TARGET.ibex.index
			rm -f $TARGET.ibex.index.data
	done;
	exit 0
	;;

	l2w) # Thunderbird Linux -> Windows
	echo "Synchronizing Thunderbird LINUX -> WINDOWS..."
	echo "Press CTRL-C to cancel..."
	for SOURCE in `find $THUNDERBIRD -type f \
		| grep -v "\.dat" \
		| grep -v "\.msf" \
		| grep -v "\.html" \
		| grep -v "Unsent" \
		| grep -v "Trash" \
		| grep -v "Junk" \
		| sort`;
		do
			TARGET=`echo "$SOURCE" | sed "s|$THUNDERBIRD|$WINDOWS|g"`
			echo "Syncing `basename "$SOURCE"`"
			"$COMMAND" "$ARGUMENTS" "$SOURCE" "$TARGET"
			# Kill the indexes. Thunderbird will regenerate them at startup.
			rm -f $TARGET.msf
	done;
			echo "Copying Addressbook"
			cp $THUNDERBIRD_DIR/abook.mab $WINDOWS_DIR/abook.mab
	exit 0
	;;

	w2l) # Thunderbird Windows -> Linux
	echo "Synchronizing Thunderbird WINDOWS -> LINUX..."
	echo "Press CTRL-C to cancel..."
	for SOURCE in `find $WINDOWS -type f \
		| grep -v "\.dat" \
		| grep -v "\.msf" \
		| grep -v "\.html" \
		| grep -v "Unsent" \
		| grep -v "Trash" \
		| grep -v "Junk" \
		| sort`;
		do
			TARGET=`echo "$SOURCE" | sed "s|$WINDOWS|$THUNDERBIRD|g"`
			echo "Syncing `basename "$SOURCE"`"
			"$COMMAND" "$ARGUMENTS" "$SOURCE" "$TARGET"
			# Kill the indexes. Thunderbird will regenerate them at startup.
			rm -f $TARGET.msf
	done;
			echo "Copying Addressbook"
			cp $WINDOWS_DIR/abook.mab $THUNDERBIRD_DIR/abook.mab
	exit 0
	;;

	*) # No Argument Provided
	echo $"Usage: $0 {e2t|t2e|l2w|w2l}"
	exit 1
esac

