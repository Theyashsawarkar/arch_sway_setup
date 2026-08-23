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
    | wofi --dmenu --prompt "Power" --width 460 --height 280 --columns 2 \
        --style ~/.config/wofi/power-style.css)
# NOT --hide-search: it's buggy in this wofi build (v1.5.3) and breaks
# entry rendering entirely when combined with --dmenu (confirmed by
# testing side by side -- the grid rendered empty with --hide-search,
# fine without it). The search box is hidden visually via CSS instead
# (#input collapsed to 0 height in power-style.css), which keeps it
# functionally present so wofi doesn't hit whatever internal path
# --hide-search breaks.
#
# NOT close_on_focus_loss=true either: sway's focus_follows_mouse
# defaults to "yes" (unset in sway/config = default), which focuses
# whatever's under the cursor on mere hover, not just on click. Combined
# with close_on_focus_loss, the popup was closing the instant the mouse
# moved off it at all, not just on an actual click elsewhere -- and
# focus_follows_mouse can't be scoped per-window in sway (checked
# sway.5, it's a global-only command), so fixing that for real would
# mean click-to-focus for the entire desktop, a much bigger change than
# asked for. Dismissing via Escape or picking an option instead, same
# as every other wofi popup in this setup (app launcher, calculator,
# emoji picker) already works.

case "$choice" in
    "$ICON_LOCK")     swaylock -C ~/.config/sway/lockconfig ;;
    "$ICON_LOGOUT")   swaymsg exit ;;
    "$ICON_SUSPEND")  systemctl suspend ;;
    "$ICON_REBOOT")   systemctl reboot ;;
    "$ICON_SHUTDOWN") systemctl poweroff ;;
esac
