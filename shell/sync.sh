#!/bin/sh

# Execute.
if [ `uname` = Linux ]; then
    sync
else
    cmd.exe /c sync
fi

