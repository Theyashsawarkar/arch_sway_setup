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
    #
    # -o background_opacity=0.3 overrides kitty's own global 0.85
    # (kitty/kitty.conf) for this window specifically, not everywhere.
    #
    # Confirmed directly, not just theory, and worth recording since the
    # first two attempts at measuring this were misleading: whole-window
    # pixel averages are too noisy (skewed by however much text/UI is on
    # screen at the moment of capture) to compare opacity values against
    # each other reliably. The methodology that actually held up: sample
    # ONE fixed, genuinely empty patch of the window (confirmed blank via
    # a direct ASCII-art luminance dump) at the real toggle-triggered
    # window position, and diff it against a screenshot of the same exact
    # screen region with no window there at all. At 0.3, that patch reads
    # rgb(16.9, 15.0, 10.6) vs. a wallpaper-only rgb(24.0, 21.3, 15.1) for
    # the identical region -- a real, consistent ~7-9 point shift per
    # channel, in the same direction kitty's own default (near-black,
    # unpainted) cell background always pulls a blend: `background_opacity`
    # is kitty's OWN-fill weight, not the wallpaper's, so a LOWER value
    # means less of kitty's black mixed in, not more -- 0.3 is already the
    # more-transparent end of what's usable here, and the shift this small
    # is exactly what "30% of a near-black fill" should produce. This
    # matches the same dark-glass look already used everywhere else in
    # this desktop (waybar, mako, wofi, nwg-bar all use Deep Midnight
    # #11111B translucent surfaces, not light ones), so a darker- rather
    # than lighter-than-wallpaper shift is the correct visual family, not
    # a bug. Text legibility reconfirmed directly at 0.3 via a fresh ASCII
    # luminance dump of real rendered text -- glyphs stayed crisp and high
    # contrast, no legibility regression from lowering opacity further.
    setsid kitty --class rmpc -o background_opacity=0.3 -e rmpc >/dev/null 2>&1 &
fi
