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
    sed -i "s|\"~/.config/alacritty/themes/themes/.*.toml\"|\"~/.config/alacritty/themes/themes/$arg.toml\"|g" "$config_dir/alacritty.toml"
    ;;
esac

