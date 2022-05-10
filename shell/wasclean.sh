#!/bin/sh

user=rubin
group=users
profile=/opt/was/data/regular/wasdev01

rm -rf $profile/wstemp
mkdir -p $profile/wstemp

rm -rf $profile/workspace
mkdir -p $profile/workspace

rm -rf $profile/temp
mkdir -p $profile/temp

rm -f $profile/logs/*.log
rm -f $profile/logs/server1/*.*
rm -f $profile/logs/ffdc/*.*
rm -f $profile/logs/wsadmin*

chown -R $user:$group $profile
