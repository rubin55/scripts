#!/bin/bash


echo "Setting bspwm colors.."
bspc config normal_border_color     "$(getcolor background)"
bspc config active_border_color     "$(getcolor color4)"
bspc config focused_border_color    "$(getcolor color4)"

echo "Setting Xresources colors.."
xrdb -load ~/.Xresources

echo "Done. Please note that currently open X11 windows need to be reopened"
echo "for the color changes to take effect. The bspwm changes are immediate."
