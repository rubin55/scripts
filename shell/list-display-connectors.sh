#!/bin/sh
for p in /sys/class/drm/*/status; do 
  con=${p%/status}; 
  echo -n "${con#*/card?-}: "; 
  cat $p; 
done
