#!/usr/bin/env bash
# Reports the running-container count for waybar as JSON (same pattern as
# caffeine-status.sh). Icon and count are colored independently via inline
# Pango spans -- icon stays a constant Blue identity color, count switches
# Green/gray depending on whether anything is actually running, so the
# "class" field still drives a border-color tint on the pill itself
# (see style.css) without duplicating that same signal in the text color.

ICON=$''
count=$(docker ps -q | wc -l)

if [ "$count" -gt 0 ]; then
    class="running"
    count_color="#A6E3A1"  # Green -- containers actually running
    tooltip="$count container(s) running"
else
    class="idle"
    count_color="#6C7086"  # dim gray -- matches every other "off" state
    tooltip="No containers running"
fi

text="<span color='#89B4FA'>$ICON</span>  <span color='$count_color'>$count</span>"
printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$class" "$tooltip"
