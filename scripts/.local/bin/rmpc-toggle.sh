#!/usr/bin/env bash
# Toggles rmpc's floating window open/hidden via sway's scratchpad --
# not process-kill-based like toggle-popup.sh, deliberately: scratchpad
# show/hide is purely a window-visibility operation, it never touches
# the underlying process, and playback lives in mpd.service (a real,
# independent systemd --user daemon) regardless of whether rmpc's own
# window is open at all -- closing rmpc entirely wouldn't even stop
# playback, let alone just hiding it.
#
# First launch: no window exists yet -- start it, and the for_window
# rule in sway/config (floating + sized + centered + moved into the
# scratchpad, shown immediately) handles making it appear correctly.
# Every press after that: the window already exists, so just toggle its
# scratchpad visibility -- verified directly (on this same pattern, for
# termusic before it) that `scratchpad show` on a window already shown
# from the scratchpad hides it again, not a no-op.
set -uo pipefail

if pgrep -x rmpc >/dev/null; then
    swaymsg '[app_id="^rmpc$"] scratchpad show' >/dev/null
else
    # setsid + redirected stdio -- without this, kitty inherits this
    # script's own stdout/stderr, and whatever launched this script (a
    # sway `exec`, a shell) can end up blocking on those file
    # descriptors staying open for as long as kitty runs, rather than
    # returning immediately the way a background launch should.
    setsid kitty --class rmpc -e rmpc >/dev/null 2>&1 &
fi
