#!/bin/sh

FILE=$1

if [ -z $1 ]; then
    echo "Please specify opsware jnlp file like so:"
    echo "$0 foo.jnlp"
    echo "or:"
    echo "$0 http://10.244.224.1/webstart/clipsa01_en.jnlp"
    exit 1
fi

export JAVA_HOME=/opt/java/sun-1.4.2_19
export JAVAWS_BINARY=/opt/java/sun-1.4.2_19/jre/javaws/javaws
export PATH=$JAVA_HOME/bin:$PATH

hash -r

$JAVAWS_BINARY $FILE &
rm -rf "D\:\\People\\$USERNAME\\.opsware\*"
