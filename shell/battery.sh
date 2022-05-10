#!/bin/bash
battery="$(acpi -b 2> /dev/null | awk "{print $1}" | sed 's/\([^:]*\): \([^,]*\), \([0-9]*\)%.*/\3/')"
if [ "$battery" ]; then
    echo $battery"%"
else
    echo "no battery"
fi
