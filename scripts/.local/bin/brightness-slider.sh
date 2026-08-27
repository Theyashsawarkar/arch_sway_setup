#!/bin/bash
# Draggable brightness slider (opened by clicking the waybar backlight
# module). zenity's --scale dialog inherits the system GTK theme, so this
# renders in Catppuccin Mocha with zero extra CSS. --print-partial streams
# the live value on every drag frame; each line is applied immediately via
# brightnessctl, giving a real-time slider instead of a set-once popup.
#
# Requires `zenity` (pacman -S zenity) -- not pulled in automatically since
# this session has no sudo access to install it.

current=$(brightnessctl -m | cut -d, -f4 | tr -d '%')

zenity --scale \
    --title="Brightness" \
    --text="Drag to adjust screen brightness" \
    --min-value=1 \
    --max-value=100 \
    --value="$current" \
    --step=1 \
    --print-partial |
while IFS= read -r value; do
    brightnessctl set "${value}%" >/dev/null
done
