#!/bin/bash

PATH=$HOME/Syncthing/Source/RAAF/scripts/shell:$PATH

export LC_ALL=C

fn="$(getfont.sh fc 0)"
bg="$(getcolor.sh background)"
fg="$(getcolor.sh foreground)"
se="$(getcolor.sh color9)"

application=$(
    wmctrl -l |\
    cut -d' ' -f5- |\
    dmenu -i -p 'Switch to' -fn "$fn" -nb "$bg" -sb "$se" -nf "$fg" -sf "$fg" $@
)

# remove special characters that mess up with xdotool search ([]~)
application=$(echo $application | sed 's/\[/./' | sed 's/\]/./' | sed 's/\~/./')

# Switch to chosen application
case $application in
    gimp | truecrypt)
        xdotool search --onlyvisible -classname "$application" windowactivate &> /dev/null
        ;;
    *)
        xdotool search ".*${application}.*" windowactivate &> /dev/null
        ;;
esac

unset LC_ALL
