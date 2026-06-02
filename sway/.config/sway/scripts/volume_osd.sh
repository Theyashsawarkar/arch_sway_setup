#!/bin/bash

# Apply the volume change
pactl set-sink-volume @DEFAULT_SINK@ "$1"

# Extract the new volume percentage
percentage=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n 1)

# Fire the notification with a progress bar
# Extract volume and ensure it captures the int properly
percentage=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n 1)
notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -h int:value:"$percentage" "Volume" "${percentage}%"
