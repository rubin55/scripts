#!/bin/sh

ac_state=$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type)
bt_state=$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type)

if [[ $ac_state =~ nothing ]]; then
    echo "switching suspend type from $ac_state to 'suspend'"
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type suspend
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type suspend
else
    echo "switching suspend type from $ac_state to 'nothing'"
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type nothing
fi
