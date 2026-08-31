#!/usr/bin/env bash
# Toggles termusic's floating window open/hidden via sway's scratchpad --
# not process-kill-based like toggle-popup.sh, deliberately: scratchpad
# show/hide is purely a window-visibility operation, it never touches
# the underlying process. Confirmed directly: the same termusic client
# and termusic-server PIDs stay up the entire time across a hide/show
# cycle, and the server's own log shows no disconnect/reconnect at all
# during it -- the client doesn't even drop its connection while hidden,
# so playback (and the client's own state) is untouched either way.
#
# First launch: no window exists yet -- start it, and the for_window
# rule in sway/config (floating + sized + centered + moved into the
# scratchpad, shown immediately) handles making it appear correctly.
# Every press after that: the window already exists, so just toggle its
# scratchpad visibility -- verified directly that `scratchpad show` on a
# window already shown from the scratchpad hides it again (not a no-op),
# so this alone gives real open/close toggling, matching every other
# popup in this repo now toggling from its own keybinding too.
set -uo pipefail

if pgrep -x termusic >/dev/null; then
    swaymsg '[app_id="^termusic$"] scratchpad show' >/dev/null
else
    # setsid + redirected stdio -- without this, kitty inherits this
    # script's own stdout/stderr, and whatever launched this script (a
    # sway `exec`, a shell) can end up blocking on those file
    # descriptors staying open for as long as kitty runs, rather than
    # returning immediately the way a background launch should.
    setsid kitty --class termusic -e termusic >/dev/null 2>&1 &
fi
