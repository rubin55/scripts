#!/bin/sh

for game in $(ps ax | grep fos | cut -d / -f 14 | sort -u | tr '\n' ' '); do
  cat ~/Steam/steamapps/*${game}* | grep name | cut -d \" -f 4
done
