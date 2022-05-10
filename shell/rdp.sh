#!/bin/sh

HOST=$1
TITLE=$2

rdesktop -0 -g 1024x768 -b -B -T "$TITLE" -N -a 16 -z -x l -r disk:home=/home/rubin $HOST
