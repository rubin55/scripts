#!/bin/sh

cd /home/$USER/Source
case "$1" in
    check)
    COMMAND="svn st"
    ;;
    update)
    COMMAND="svn up"
    ;;
    commit)
    COMMAND="svn commit"
    ;;
    *)
    echo $"Usage: $0 {check|update|commit}"
    exit 1
esac
    
for WORKSPACE in `ls`; do
    cd $WORKSPACE 
    for PROJECT in `ls`; do 
        cd $PROJECT 
        echo "Checking: $WORKSPACE/$PROJECT"
        $COMMAND
        cd ..
    done 
    cd .. 
done
