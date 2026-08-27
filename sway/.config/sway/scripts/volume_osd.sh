#!/bin/bash
# Volume OSD helper: adjusts, or toggles mute on, the default sink, then
# fires a progress-bar-style mako notification. Used by both the
# XF86Audio* keybindings and the waybar pulseaudio module (click/scroll).

if [ "$1" = "mute-toggle" ]; then
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    if pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes; then
        notify-send -h string:x-canonical-private-synchronous:sys-notify -u low "Volume" " Muted"
    else
        percentage=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n 1)
        notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -h int:value:"$percentage" "Volume" "${percentage}%"
    fi
    exit 0
fi

# Raising/lowering should always be audible, so drop mute first.
pactl set-sink-mute @DEFAULT_SINK@ 0

# Apply the volume change
pactl set-sink-volume @DEFAULT_SINK@ "$1"

# Extract the new volume percentage
percentage=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n 1)

# Fire the notification with a progress bar
notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -h int:value:"$percentage" "Volume" "${percentage}%"
