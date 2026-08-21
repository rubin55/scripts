#!/bin/sh
# Wrapper that forces mednaffe (GTK3) to follow the desktop
# light/dark preference, which it otherwise ignores.

theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null |
	tr -d "'")
[ -n "$theme" ] || theme=Adwaita

# Prefer the xdg-desktop-portal value, fall back to gsettings.
# color-scheme: 0 = no preference, 1 = dark, 2 = light.
scheme=$(gdbus call --session \
	--dest org.freedesktop.portal.Desktop \
	--object-path /org/freedesktop/portal/desktop \
	--method org.freedesktop.portal.Settings.Read \
	org.freedesktop.appearance color-scheme 2>/dev/null |
	tr -cd '0-9')

case "$scheme" in
1) dark=yes ;;
2) dark=no ;;
*)
	case $(gsettings get org.gnome.desktop.interface color-scheme \
		2>/dev/null) in
	*prefer-dark*) dark=yes ;;
	*) dark=no ;;
	esac
	;;
esac

[ "$dark" = yes ] && theme="$theme:dark"

GTK_THEME="$theme" exec /usr/bin/mednaffe "$@"
