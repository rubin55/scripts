#!/bin/bash

echo "Running: $@ in the background and redirecting output to /tmp/backgrounded.txt.."
sleep 1
echo "# $@" > /tmp/backgrounded.txt
"$@" >> /tmp/backgrounded.txt 2>&1 &
