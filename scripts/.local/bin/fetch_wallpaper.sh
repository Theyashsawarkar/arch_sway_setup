#!/bin/bash

BASE_DIR="$HOME/Pictures/Wallpapers"
ACTIVE_DIR="$BASE_DIR/Active"
ARCHIVE_DIR="$BASE_DIR/Archive"

# 1. Move existing active wallpapers to the archive
mv "$ACTIVE_DIR"/* "$ARCHIVE_DIR"/ 2>/dev/null

# 2. Set the new filename using today's date
FILEPATH="$ACTIVE_DIR/wallpaper-$(date +%Y%m%d).jpg"

# 3. Download the new high-res image
curl -sL "https://bing.biturl.top/?resolution=1920&format=image&index=0&mkt=en-US" -o "$FILEPATH"

# 4. If the download was successful, link and apply
if [ -s "$FILEPATH" ]; then
    # Create a static symlink that Sway can always find
    ln -sf "$FILEPATH" "$BASE_DIR/current.jpg"
    
    # Apply it immediately via Sway IPC
    export SWAYSOCK=$(ls /run/user/$(id -u)/sway-ipc.*.sock 2>/dev/null | head -n 1)
    if [ -n "$SWAYSOCK" ]; then
        swaymsg "output * bg '$BASE_DIR/current.jpg' fill"
    fi
fi
