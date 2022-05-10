#!/bin/sh

alias session='/home/rubin/Source/Projects/Eclipse/session/target/ant-build/session.sh'

localAddr="127.0.0.1"
localHost="tezro"
localUser="$USER"
localDir="/home/rubin/IBM/Source/Projects/Eclipse"

remoteAddr="172.17.1.48"
remoteHost="donald"
remoteUser="was"
remoteDir="/data/was/build"

project="$1"
if [ ! -e "$localDir/$project/pom.xml" ]; then
    echo "Please specify a valid maven project."
    echo "I'm looking in: $localDir"
    exit 1
fi

. ~/.session/tmp/session.ssh-agent.out

echo "[INFO] Sending $project to $remoteHost:$remoteDir/$project"
rsync -avzPHSc --delete --quiet $localDir/$project/ $remoteUser@$remoteAddr:$remoteDir/$project/

echo "[INFO] Invoking packaging build on $remoteHost:$remoteDir/$project"
session tell $remoteHost --command="'mvn -f $remoteDir/$project/pom.xml package'"

echo "[INFO] Deploying $project on WebSphere Application Server running on $remoteHost" 
session tell $remoteHost --command="'/apps/was/as/traditional/bin/wsadmin.sh -user admin -password WASMASTER -lang jython -f /data/was/deploy/$project.py'"
