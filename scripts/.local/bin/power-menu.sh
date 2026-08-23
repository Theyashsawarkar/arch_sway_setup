#!/usr/bin/env bash
# Compact power menu -- a wofi --dmenu popup (same scale/material as the
# app launcher, not a full-screen modal) rather than wlogout, whose grid
# always spreads buttons across the full screen width regardless of CSS
# or spacing flags (confirmed by measurement, not assumed -- see
# CHANGELOG.md for the details).
#
# Single row via orientation=horizontal, not --columns: --columns caps
# at 2 per row in this wofi build (v1.5.3) for --dmenu mode -- tested
# repeatedly at several widths and via both the CLI flag and a config
# file, never rendered more than 2 per row. orientation=horizontal isn't
# subject to that cap and lays all 5 out in one row directly.
#
# Icon-only entries (no text label) -- kept cells uniform width.

ICON_LOCK=$'\uf023'
ICON_LOGOUT=$'\uf08b'
ICON_SUSPEND=$'\uf186'
ICON_REBOOT=$'\uf021'
ICON_SHUTDOWN=$'\uf011'

choice=$(printf '%s\n%s\n%s\n%s\n%s\n' \
    "$ICON_LOCK" "$ICON_LOGOUT" "$ICON_SUSPEND" "$ICON_REBOOT" "$ICON_SHUTDOWN" \
    | wofi --dmenu --prompt "Power" --width 650 --height 150 \
        -D orientation=horizontal --hide-scroll \
        --style ~/.config/wofi/power-style.css)
# NOT --hide-search: it's buggy in this wofi build and breaks entry
# rendering entirely when combined with --dmenu (confirmed by testing
# side by side). The search box is hidden visually via CSS instead
# (#input collapsed to 0 height in power-style.css).
#
# NOT close_on_focus_loss=true: confirmed in actual real-world use (not
# just reasoning about it) that sway's focus_follows_mouse (defaults to
# "yes", unset in sway/config) closes the popup the instant the pointer
# moves toward *any* other window, not just on an actual click -- hover
# alone changes focus under that setting. focus_follows_mouse is a
# global-only sway command (checked sway.5, no for_window equivalent),
# so a real fix would mean click-to-focus for the entire desktop, well
# beyond this popup. Dismissing via Escape or picking an option instead,
# same as every other wofi popup in this setup already works.

case "$choice" in
    "$ICON_LOCK")     swaylock -C ~/.config/sway/lockconfig ;;
    "$ICON_LOGOUT")   swaymsg exit ;;
    "$ICON_SUSPEND")  systemctl suspend ;;
    "$ICON_REBOOT")   systemctl reboot ;;
    "$ICON_SHUTDOWN") systemctl poweroff ;;
esac
