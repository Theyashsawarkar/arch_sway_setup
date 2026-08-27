#!/usr/bin/env bash
# Reports the running-container count for waybar as JSON (same pattern as
# caffeine-status.sh) so the custom/docker module can be styled distinctly
# when containers are actually running vs sitting idle.

ICON=$''
count=$(docker ps -q | wc -l)

if [ "$count" -gt 0 ]; then
    printf '{"text":"%s  %s","class":"running","tooltip":"%s container(s) running"}\n' "$ICON" "$count" "$count"
else
    printf '{"text":"%s  %s","class":"idle","tooltip":"No containers running"}\n' "$ICON" "$count"
fi
