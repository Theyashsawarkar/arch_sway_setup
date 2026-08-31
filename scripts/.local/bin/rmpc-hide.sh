#!/usr/bin/env bash
# Bound to Escape inside rmpc's own kitty window (via a kitty `-o map`
# override on its launch line, rmpc-toggle.sh) -- hides the popup the
# same way pressing $mod+Shift+m a second time does: sway's scratchpad,
# not a process kill, so MPD itself is untouched either way (see
# rmpc-toggle.sh's own comment for the full reasoning).
#
# A dedicated script rather than embedding the swaymsg call directly in
# kitty's own `-o map` value: that value already has to survive one
# layer of shell quoting to reach kitty as a single argument, and the
# `[app_id="^rmpc$"]` criteria needs its own quotes nested inside that --
# exactly the kind of thing that goes silently wrong instead of erroring
# loudly. A real script file sidesteps the whole problem.
#
# Why kitty intercepts Escape at all instead of leaving it to rmpc:
# rmpc's own config (config.ron) already binds "<Esc>" to its internal
# `Close` action (closes whatever modal/dialog is currently open inside
# rmpc -- a save-playlist prompt, etc.), which has nothing to do with
# sway's scratchpad and doesn't hide the window. Direct feedback: "all
# popup modals should also hide when esc key is pressed as well" -- every
# other popup in this desktop (every wofi-based one, nwg-bar) already
# closes on Escape natively; rmpc's own floating window was the one real
# gap, confirmed live (focused it, sent Escape, window stayed open).
#
# Intercepting Escape at the kitty level for this window does mean
# rmpc's own internal `Close` action becomes unreachable via Escape
# specifically -- but it's not actually lost: `"<C-c>": Close` is bound
# to the exact same action in config.ron already, so closing an internal
# modal still has a working key, just Ctrl+C instead of Escape now.
set -uo pipefail
swaymsg '[app_id="^rmpc$"] scratchpad show' >/dev/null
