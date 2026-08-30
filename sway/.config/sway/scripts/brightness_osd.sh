#!/bin/bash
# Brightness OSD helper: applies a brightnessctl delta, then fires a
# progress-bar-style mako notification. Used by both the
# XF86MonBrightness* keybindings and the waybar backlight module's
# on-scroll bindings.
#
# flock-serialized for the same reason as volume_osd.sh: this can fire in
# rapid bursts (touchpad smooth-scroll deltas). brightnessctl already
# clamps at 0-100% on its own (verified: "set 1000%" lands at 100%, not an
# overdrive risk the way pactl's relative volume is), but without the lock
# concurrent calls can still stack out of order and overshoot the expected
# per-tick step before settling.
LOCK="/tmp/brightness_osd.lock"

(
    flock -x 9
    brightnessctl set "$1" >/dev/null
) 9>"$LOCK"

percentage=$(brightnessctl -m | cut -d, -f4 | tr -d '%')

# Real (absolute-path) icon, not a theme name -- mako has no GTK-style
# theme resolution, only ever searches hicolor/pixmaps plus icon-path
# (see mako/config), and even with Papirus added to icon-path, most
# "-symbolic" names in it use `fill:currentColor` defaulting to a dark
# #444444 meant for light UI chrome -- on this desktop's near-black
# notification background that rendered as good as invisible (confirmed
# with a real screenshot: the icon region differed from a no-icon control
# by thousands of pixels, but not one exact-color match, all sub-perceptible
# dark-on-dark antialiasing). Papirus's "status" and "apps" categories use
# real hardcoded fills instead -- this is display-brightness.svg from
# there, confirmed `grep -c currentColor` is 0 before using it.
ICON=/usr/share/icons/Papirus/48x48/apps/display-brightness.svg

[ -n "$percentage" ] && notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -h int:value:"$percentage" -i "$ICON" "Brightness" "${percentage}%"
