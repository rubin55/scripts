#!/bin/bash

# Initialize the environment, then exec the wrapped command.
source ~/.bashrc
exec "$@"
