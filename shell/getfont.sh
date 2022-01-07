#!/bin/sh

alias error='>&2 echo'

style=$1
fontString="$(cat ~/.Xresources | grep '^#define FIXFONT' |sed -n 's/^.*xft/xft/p')"

case $style in
    xft)
    echo -n "$fontString"
    ;;
    fc)
    offset=$2
    name=$(echo $fontString | cut -d: -f2)
    pixelSize=$(echo $fontString | cut -d: -f3 | cut -d, -f 1| cut -d= -f2)

    if [ -z "$offset" ]; then
    	error "no offset specified. will set pointSize to $pixelSize"
	pointSize=$pixelSize
    else
    	pointSize=$((pixelSize + offset))
        error "setting pointSize to $pixelSize and offsetting with $offset = $pointSize"
    fi

    echo -n "$name-$pointSize"
    ;;
    *)
    error "no style specified."
    error "please specify either xft or fc!"
    exit 1
esac
