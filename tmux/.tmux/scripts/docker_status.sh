#!/usr/bin/env bash
# Docker segment for the tmux status bar.
#
# Shows a docker icon + running-container count whenever the docker daemon
# is reachable, even if that count is zero. Prints nothing (hiding the
# segment) if the daemon isn't up, so it doesn't clutter the bar.

icon=$'\uf308' # nf-linux-docker (U+F308)

running=0
if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet docker 2>/dev/null; then
    running=1
elif pgrep -x dockerd >/dev/null 2>&1; then
    running=1
fi

[ "$running" -eq 1 ] || exit 0

count=$(docker ps -q 2>/dev/null | wc -l)

# Segment background is Catppuccin Mocha teal (#94e2d5, light/pastel), so text
# needs dark, saturated colors to stay readable against it.
if [ "$count" -gt 0 ]; then
    count_color="#1b8a5a"   # dark saturated green: containers running
else
    count_color="#1e1e2e"   # base: idle/neutral
fi

printf '#[fg=#2496ED]%s  #[fg=#1e1e2e]x#[fg=%s] %s' "$icon" "$count_color" "$count"
