#!/usr/bin/env bash
# Reports notification history count for waybar (see
# notification-history.py, the actual viewer this icon opens). Count
# comes straight from `makoctl history -j`'s own array length rather than
# a separately-tracked counter -- one source of truth, can't drift out of
# sync with what the viewer itself will show.

ICON=''  # fa-bell

count=$(makoctl history -j 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null)
count="${count:-0}"

if [ "$count" -gt 0 ]; then
    class="has-history"
    tooltip="$count notification(s) in history -- click to view"
else
    class="empty"
    tooltip="No notification history yet"
fi

printf '{"text":"%b","class":"%s","tooltip":"%s"}\n' "$ICON" "$class" "$tooltip"
