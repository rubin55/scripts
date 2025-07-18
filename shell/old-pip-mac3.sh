#!/bin/sh

PYTHON_VERSION=3.8
PYTHON_LOCAL_HOME="$HOME/Library/Python/$PYTHON_VERSION/bin"

if [ "$1" == "install" ]; then
    echo "Install  argument passed, rewriting command to:"
    cmd="pip$PYTHON_VERSION install --user --install-option="--install-scripts=$PYTHON_LOCAL_HOME/bin" $2 $3 $4 $5 $6 $7 $8 $9"
    echo "$cmd"
    sleep 4
    eval "$cmd"
else
    cmd="pip$PYTHON_VERSION $*"
    eval "$cmd"
fi
