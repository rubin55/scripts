#!/usr/bin/env bash

aider_conf="$HOME/.aider.conf.yml"

red=$(ghostty +show-config | grep 'palette = 1=#' | cut -d# -f2)
green=$(ghostty +show-config | grep 'palette = 2=#' | cut -d# -f2)
yellow=$(ghostty +show-config | grep 'palette = 3=#' | cut -d# -f2)
blue=$(ghostty +show-config | grep 'palette = 4=#' | cut -d# -f2)
magenta=$(ghostty +show-config | grep 'palette = 5=#' | cut -d# -f2)

sed -i "s|^assistant-output-color: [\s]*.*$|assistant-output-color: \'$green\'|g" "$aider_conf" > /dev/null 2>&1
sed -i "s|^tool-error-color: [\s]*.*$|tool-error-color: \'$red\'|g" "$aider_conf" > /dev/null 2>&1
sed -i "s|^tool-output-color: [\s]*.*$|tool-output-color: \'$magenta\'|g" "$aider_conf" > /dev/null 2>&1
sed -i "s|^tool-warning-color: [\s]*.*$|tool-warning-color: \'$yellow\'|g" "$aider_conf" > /dev/null 2>&1
sed -i "s|^user-input-color: [\s]*.*$|user-input-color: \'$blue\'|g" "$aider_conf" > /dev/null 2>&1
