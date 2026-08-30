#!/usr/bin/env bash
# Reapplies whatever notification mode was last chosen via
# notification-mode.sh -- run right after `exec mako` in sway/config,
# the same pattern already used for swayidle-startup.sh/caffeine mode.
# Needed because mako's own mode selection resets to "default" on every
# mako restart/login (confirmed directly while building this, not
# assumed), so without this, choosing "dnd" once wouldn't survive a
# reboot or a mako crash-and-restart -- it would silently drop back to
# popups-and-sound with no indication anything changed.
set -uo pipefail

STATE_FILE="$HOME/.local/state/notification-mode/current"
mode=$(cat "$STATE_FILE" 2>/dev/null || true)

case "$mode" in
    normal|silent|dnd) ;;
    *) mode="normal" ;;
esac

# mako needs a moment to actually be up and registered on the session
# bus before makoctl can talk to it -- this runs immediately after `exec
# mako` in sway/config, so there's a real startup race here, the same
# class of issue fetch_wallpaper.sh's own sway-IPC-socket retry loop
# already documents elsewhere in this repo. A short bounded retry
# instead of a single instant attempt.
for _ in $(seq 1 10); do
    if makoctl mode -s "$mode" 2>/dev/null; then
        exit 0
    fi
    sleep 0.5
done
