#!/usr/bin/env bash
# Compact power menu -- a wofi --dmenu grid popup (same scale/material as
# the app launcher, not a full-screen modal) rather than wlogout, whose
# grid always spreads buttons across the full screen width regardless of
# CSS or spacing flags (confirmed by measurement, not assumed -- see
# CHANGELOG.md for the details).
#
# Icon-only entries (no text label): text-labeled entries made columns
# render at uneven widths. --columns is capped at 2 in this wofi version
# (v1.5.3) for --dmenu mode specifically -- 3 was requested and tested at
# several widths (300/400/700px) and via both the CLI flag and a config
# file, and never rendered as more than 2 per row. 5 items in 2 columns
# gives a clean 2+2+1 grid, which is what's actually achievable here.

ICON_LOCK=$''
ICON_LOGOUT=$''
ICON_SUSPEND=$''
ICON_REBOOT=$''
ICON_SHUTDOWN=$''

choice=$(printf '%s\n%s\n%s\n%s\n%s\n' \
    "$ICON_LOCK" "$ICON_LOGOUT" "$ICON_SUSPEND" "$ICON_REBOOT" "$ICON_SHUTDOWN" \
    | wofi --dmenu --prompt "Power" --width 220 --height 320 --columns 2 \
        --style ~/.config/wofi/power-style.css)

case "$choice" in
    "$ICON_LOCK")     swaylock -C ~/.config/sway/lockconfig ;;
    "$ICON_LOGOUT")   swaymsg exit ;;
    "$ICON_SUSPEND")  systemctl suspend ;;
    "$ICON_REBOOT")   systemctl reboot ;;
    "$ICON_SHUTDOWN") systemctl poweroff ;;
esac
