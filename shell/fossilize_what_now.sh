#!/bin/sh

for game in $(ps ax | grep fos | cut -d / -f 14 | sort -u | tr '\n' ' '); do
  cat ~/Steam/steamapps/appmanifest_${game}.acf | grep name | cut -d \" -f 4
done
