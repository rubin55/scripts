#!/bin/bash

# Prefer pip3, else pip2, else whatever you have.
if [ -x "/usr/bin/pip3" ]; then
    pip=/usr/bin/pip3
elif [ -x "/usr/bin/pip2" ]; then
    pip=/usr/bin/pip2
else
    pip=`which pip`
fi

# Prefer python3, else python2, else whatever you have.
if [ -x "/usr/bin/python3" ]; then
    python=/usr/bin/python3
elif [ -x "/usr/bin/python2" ]; then
    python=/usr/bin/python2
else
    python=`which python`
fi

# Set PYTHON_LOCAL_HOME if not set.
if [ -z "$PYTHON_LOCAL_HOME" ]; then
    PYTHON_VERSION=$("$python" -V | awk '{print $2}')
    PYTHON_LOCAL_HOME="$HOME/.python/$PYTHON_VERSION"
fi

if [ "$1" == "install" ]; then
    echo "Install  argument passed, rewriting command to:"
    cmd="$pip install --user --install-option="--install-scripts=$PYTHON_LOCAL_HOME/bin" $2 $3 $4 $5 $6 $7 $8 $9"
    echo "$cmd"
    sleep 4
    eval "$cmd"
else
    "$pip" "$@"
fi
