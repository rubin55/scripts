#!/bin/sh

IFS=$'\x09'$'\x0A'$'\x0D'

ENABLE_KEYS_PATCH="/home/rubin/Source/Shell/firefox_enablekeys.patch"
FIREFOX_HOME=/usr/lib/firefox-`rpm -q firefox | cut -d "-" -f 2`

cd $FIREFOX_HOME/chrome
    echo "Unpacking browser.jar"
    unzip -q browser.jar
    echo "Applying enable keys patch"
    cat $ENABLE_KEYS_PATCH | patch -p0
    echo "Repacking browser.jar"
    zip -qrD0 browser.jar content/browser/
    echo "Cleaning up"
    rm -rf $FIREFOX_HOME/chrome/content/
cd -


