#!/usr/bin/env bash

tmux list-sessions > /dev/null 2>&1
if [ $? -ge 1 ]; then
	exec tmux new-session -A -s 0
else
	exec bash
fi