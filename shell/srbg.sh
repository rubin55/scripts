#!/usr/bin/env bash

directory="$1"

if [ -z "$directory" ]; then
    echo "You must pass the path of a directory with images."
    exit 1
fi

tmpdir=/tmp/srbg.$USER
mkdir -p $tmpdir
rm -f $tmpdir/*

count=1
for active_resolution in $(xrandr | grep '*+' | awk '{print $1}'); do 
    image_original="$(find $directory -maxdepth 1 \( -name  \*.jpg -o -name \*.png \) | sort -R | tail -1)"
    image_resized="$tmpdir/$count."${image_original##*.}""
    convert "${image_original}" -resize ${active_resolution}^  -gravity center -extent ${active_resolution} "${image_resized}"
    ((count++))
done

#((count--))
#if [ $count == 1 ]; then
#    echo "Single display detected, assuming low-quality LVDS."
#    echo "Adjusting color temperature to 5000K."
#    redshift -O 5000
#fi

convert $tmpdir/* +append $tmpdir/0.png
hsetroot -fill $tmpdir/0.png

