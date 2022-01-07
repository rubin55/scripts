#!/bin/bash

directories="Documents Pictures Music Source"
for dir in $directories; do
    echo "Syncing $dir, please be patient.."
    sleep 2
    rsync -av --delete -PHSz /home/rubin/$dir/ 172.17.1.5:/home/rubin/$dir/
done;
