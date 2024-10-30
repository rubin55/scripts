#!/bin/sh
arg="$1"
config_dir="$HOME/.config/alacritty"

if [ -z "$arg" ]; then
    arg="list"
fi

case $arg in
    list)
    ls "$config_dir/themes/themes/"
    ;;
    *)
    if [ -e "$config_dir/themes/themes/$arg" ]; then
        sed -i "s|\"~/.config/alacritty/themes/themes/.*.toml\"|\"~/.config/alacritty/themes/themes/$arg\"|g" "$config_dir/alacritty.toml"
    fi
    ;;
esac

