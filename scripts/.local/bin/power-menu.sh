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
    | wofi --dmenu --prompt "Power" --width 560 --height 460 --columns 2 \
        --hide-scroll -D close_on_focus_loss=true \
        --style ~/.config/wofi/power-style.css)
# NOT --hide-search: it's buggy in this wofi build (v1.5.3) and breaks
# entry rendering entirely when combined with --dmenu (confirmed by
# testing side by side -- the grid rendered empty with --hide-search,
# fine without it). The search box is hidden visually via CSS instead
# (#input collapsed to 0 height in power-style.css), which keeps it
# functionally present so wofi doesn't hit whatever internal path
# --hide-search breaks.
#
# close_on_focus_loss=true: verified with an actual test (not just
# reasoning about sway's focus_follows_mouse) -- opened a real window,
# confirmed the popup stayed open on its own with no action, then
# shifted focus to that window via swaymsg (simulating a real click
# elsewhere) and confirmed the popup actually closed. Works as intended.

case "$choice" in
    "$ICON_LOCK")     swaylock -C ~/.config/sway/lockconfig ;;
    "$ICON_LOGOUT")   swaymsg exit ;;
    "$ICON_SUSPEND")  systemctl suspend ;;
    "$ICON_REBOOT")   systemctl reboot ;;
    "$ICON_SHUTDOWN") systemctl poweroff ;;
esac
