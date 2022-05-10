#!/bin/sh

PATH=$HOME/Syncthing/Source/RAAF/scripts/shell:$PATH

fn="$(getfont.sh fc 0)"
bg="$(getcolor.sh background)"
fg="$(getcolor.sh foreground)"
se="$(getcolor.sh color9)"
LC_ALL=en_US.UTF-8 dmenu_run -i -fn "$fn" -nb "$bg" -sb "$se" -nf "$fg" -sf "$fg"
