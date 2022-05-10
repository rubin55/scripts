#!/bin/bash
for i in {0..15} ; do
    printf "\x1b[38;5;${i}m████████████████\n"
done
