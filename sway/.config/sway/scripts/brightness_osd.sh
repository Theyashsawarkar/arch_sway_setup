#!/bin/bash

# Apply the brightness change passed from Sway (e.g., +5% or 5%-)
brightnessctl set "$1"

# Extract the new percentage
percentage=$(brightnessctl -m | cut -d, -f4 | tr -d '%')

# Fire the notification with a progress bar
# Add --hint=int:value:"$percentage" and ensure it targets your display
notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -h int:value:"$percentage" "Brightness" "${percentage}%"
