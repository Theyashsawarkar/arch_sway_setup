#!/usr/bin/env bash
# Reports the current notification mode + history count for waybar (see
# notification-history.py, the viewer this icon opens on click, and
# notification-mode.sh, what changes the mode this icon reflects).
#
# Reads the mode from the same state file notification-mode.sh writes
# and notification-mode-restore.sh reapplies at startup, not `makoctl
# mode` directly -- keeps this one script from being a second,
# independent source of truth for "what mode are we in" that could
# theoretically read stale/racy live daemon state right as a switch is
# in flight; the state file is what every other part of this feature
# already treats as authoritative.

STATE_FILE="$HOME/.local/state/notification-mode/current"
mode=$(cat "$STATE_FILE" 2>/dev/null || true)
case "$mode" in
    normal|silent|dnd) ;;
    *) mode="normal" ;;
esac

count=$(makoctl history -j 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null)
count="${count:-0}"

ICON_NORMAL=''       # fa-bell
ICON_SILENT=''       # fa-bell-slash
ICON_DND='󰪡'          # md-minus-circle

case "$mode" in
    normal)
        icon="$ICON_NORMAL"
        label="Normal"
        ;;
    silent)
        icon="$ICON_SILENT"
        label="Silent"
        ;;
    dnd)
        icon="$ICON_DND"
        label="Do Not Disturb"
        ;;
esac

tooltip="$label -- $count notification(s) in history -- click to view, scroll to change mode"

printf '{"text":"%b","class":"%s","tooltip":"%s"}\n' "$icon" "$mode" "$tooltip"
