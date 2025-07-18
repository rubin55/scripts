#!/bin/sh

NEWSLOG_EN="/home/rubin/Documents/Public/Grond News, English.txt"
NEWSLOG_NL="/home/rubin/Documents/Public/Grond Nieuws, Nederlands.txt"

echo "Write your newsitem at the end of the file, separated by "^", no newlines!"
sleep 2
vi "$NEWSLOG_EN"

echo "Copying english newsitem to dutch newsfile.."
tail -n1 "$NEWSLOG_EN" >> "$NEWSLOG_NL"

echo "Translate your english newsitem at the end of the dutch newsfile!"
sleep 2
vi "$NEWSLOG_NL"

echo "Done!"
