#!/usr/bin/env bash
# Compact power menu -- a wofi --dmenu popup (same scale/material as the
# app launcher, not a full-screen modal) rather than wlogout, whose grid
# always spreads buttons across the full screen width regardless of CSS
# or spacing flags (confirmed by measurement, not assumed -- see
# CHANGELOG.md for the details).

ICON_LOCK=$'\uf023'
ICON_LOGOUT=$'\uf08b'
ICON_SUSPEND=$'\uf186'
ICON_REBOOT=$'\uf021'
ICON_SHUTDOWN=$'\uf011'

choice=$(printf '%s  Lock\n%s  Logout\n%s  Suspend\n%s  Reboot\n%s  Shutdown\n' \
    "$ICON_LOCK" "$ICON_LOGOUT" "$ICON_SUSPEND" "$ICON_REBOOT" "$ICON_SHUTDOWN" \
    | wofi --dmenu --prompt "Power" --width 280 --height 260 \
        --style ~/.config/wofi/power-style.css)

case "$choice" in
    *Lock*)     swaylock -C ~/.config/sway/lockconfig ;;
    *Logout*)   swaymsg exit ;;
    *Suspend*)  systemctl suspend ;;
    *Reboot*)   systemctl reboot ;;
    *Shutdown*) systemctl poweroff ;;
esac
