
#!/bin/bash

# Input.
file="$1"

# Commands used.
awk=/usr/bin/awk
grep=/usr/bin/grep
sed=/usr/bin/sed
sort=/usr/bin/sort
wc=/usr/bin/wc

function emsg() {
	>&2 echo $@;
}

if [ -z "$file" ] ; then
	emsg "Usage: $0 <filename>"
	exit 1
fi

if [ ! -e "$file" ] ; then
	emsg "File \"$file\" not found, exiting..."
	exit 1
fi

if [ ! -r "$file" ] ; then
	emsg "File \"$file\" is not readable, exiting..."
	exit 1
fi

regexp="([0-9]+)(dag|uur)\.txt"
if [[ ! $file =~ $regexp ]]; then
	emsg "File \"$file\" filename is not in the expected format: $regexp"
	exit 2
fi

consistentColumnCount=$($awk '{print NF}' "$file" | $sort -u | $wc -l | $sed -e 's/[^0-9]*//g')
if [ $consistentColumnCount -ne 1 ] ; then
	emsg "File \"$file\" contains lines with differing number of columns, exiting..."
	exit 3
fi

numberOfColumns=$($awk '{print NF}' "$file" | sort -u)
case $numberOfColumns in
    12)
	if [ $($grep -c -v -E '^\s*([0-9-]+\s+){11}[0-9-]+\s*$' "$file") -gt 0 ] ; then
		emsg "File \"$file\" is not a valid 12 column file, exiting..."
		exit 4
	else
	    cat "$file"
	fi
    ;;
    21)
	if [ $($grep -c -v -E '^\s*([0-9-]+\s+){20}[0-9-]+\s*$' "$file") -gt 0 ] ; then
		emsg "File \"$file\" is not a valid 21 column file, exiting..."
		exit 4
	else
		cat "$file"
	fi
    ;;
    *)
	emsg "File \"$file\" contains $numberOfColumns instead of 12 or 21 columns, exiting..."
	exit 5
    ;;
esac
