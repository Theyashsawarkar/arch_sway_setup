#!/bin/bash

# Ensure the directory exists
mkdir -p ~/Pictures/Screenshots

# Define the filename with a timestamp
FILE="$HOME/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S_screenshot.png')"

# Capture the entire screen
grim "$FILE"

# Copy the image data to the clipboard
wl-copy < "$FILE"

# Send the notification, using the newly captured image as the icon
notify-send -h string:x-canonical-private-synchronous:sys-notify -i "$FILE" "Screenshot Captured" "Copied to clipboard and saved."
