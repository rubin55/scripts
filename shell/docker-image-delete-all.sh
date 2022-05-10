#!/usr/bin/env bash

for i in `docker image ls | awk '{print $3}'`; do docker image rm $i; done
