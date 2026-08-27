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

[ -n "$percentage" ] && notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -h int:value:"$percentage" "Brightness" "${percentage}%"
