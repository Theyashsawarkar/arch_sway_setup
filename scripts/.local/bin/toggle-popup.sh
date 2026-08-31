#!/usr/bin/env bash
# Toggles a single-instance popup (wofi --dmenu, nwg-bar, or any of this
# desktop's own wofi-based picker scripts) open/closed from one
# keybinding, instead of just always launching a new one on top.
#
# Every popup this repo launches from a keybinding was, until now,
# fire-and-open-only -- pressing the same keybinding again while it was
# already open just stacked a second instance (or did nothing useful),
# and there was no way to close one except picking an item or (for the
# wofi ones specifically) Escape, which already worked natively but only
# solved half of what was actually asked for.
#
# Why a marker file instead of matching on the popup's own process name:
# every wofi-based picker here ultimately shows up as a bare `wofi`
# process, indistinguishable from every *other* wofi-based picker by
# name alone -- `pkill -x wofi` alone can't tell "the wifi picker is
# open" from "the calculator is open". A marker file keyed by the name
# this script is called with (one per keybinding) tracks that instead.
#
# Usage: toggle-popup.sh <unique-name> <kill-process-name> <command...>
#   <unique-name>        arbitrary tag, one per keybinding (e.g. "wifi")
#   <kill-process-name>  the actual process to signal to close the popup
#                        (wofi for every wofi-based one, nwg-bar for the
#                        power menu -- whatever's still alive and blocking
#                        when the popup is "open")
#   <command...>         how to actually launch this popup
set -uo pipefail

NAME="$1"
KILL_PROC="$2"
shift 2

MARKER_DIR="$HOME/.local/state/popup-toggle"
MARKER="$MARKER_DIR/${NAME}.pid"
mkdir -p "$MARKER_DIR"

# This popup is already open (the script instance that launched it is
# still alive and blocked waiting on it) -- close it, same effect as
# pressing Escape, and stop. This is the actual "press the same
# keybinding again to hide it" behavior.
if [ -f "$MARKER" ] && kill -0 "$(cat "$MARKER" 2>/dev/null)" 2>/dev/null; then
    pkill -x "$KILL_PROC" 2>/dev/null
    rm -f "$MARKER"
    exit 0
fi

# Some *other* popup might currently be open (a different keybinding's
# wofi instance, say) -- close it first so switching between popups
# never stacks two on screen at once, then clear every stale marker
# (a script that got killed some other way, e.g. sway reload mid-popup,
# would otherwise leave a marker behind forever).
pkill -x wofi 2>/dev/null
pkill -x nwg-bar 2>/dev/null
rm -f "$MARKER_DIR"/*.pid

echo $$ > "$MARKER"
"$@"
rm -f "$MARKER"
