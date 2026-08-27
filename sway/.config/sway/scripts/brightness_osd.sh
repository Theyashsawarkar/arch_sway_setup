#!/bin/bash
# Brightness OSD helper: applies a brightnessctl delta/value, then fires a
# progress-bar-style mako notification. Used by both the XF86MonBrightness*
# keybindings and the waybar backlight module's on-scroll bindings.

brightnessctl set "$1"

percentage=$(brightnessctl -m | cut -d, -f4 | tr -d '%')

notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -h int:value:"$percentage" "Brightness" "${percentage}%"
