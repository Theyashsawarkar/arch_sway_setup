#!/bin/bash
# Volume OSD helper: adjusts, or toggles mute on, the default sink, then
# fires a progress-bar-style mako notification. Used by both the
# XF86Audio* keybindings and the waybar pulseaudio module (click/scroll).
#
# This can fire in rapid bursts (e.g. a touchpad's smooth-scroll deltas
# outrunning waybar's smooth-scrolling-threshold debounce) -- confirmed by
# forcing 30 concurrent "+5%" calls, which raced pactl's own relative-volume
# math and drove the sink to 1494%. Two defenses against that:
#   1. flock serializes read-current -> compute-target -> apply, so
#      concurrent calls stack correctly instead of racing on a stale read.
#   2. The target is clamped to 0-100 ourselves -- pactl's relative "+N%"
#      does NOT clamp on its own, so without this a burst can genuinely
#      overdrive well past 100%.
LOCK="/tmp/volume_osd.lock"

# Same tiering convention as waybar's own battery icons elsewhere in this
# desktop (different icon per range, not one static speaker glyph).
#
# Absolute paths, not theme names -- see brightness_osd.sh for the full
# story: mako has no GTK-style theme resolution, and Papirus's
# "-symbolic"/`actions` names all use `fill:currentColor` (defaults to a
# near-invisible dark #444444 on this desktop's near-black notification
# background). Papirus's `status` category ships these same four as real,
# hardcoded-fill icons instead (confirmed `grep -c currentColor` is 0 on
# all four before using them) -- only at 32x32 though, no 48x48 status
# variant exists for these specifically, so they render a bit smaller
# than this repo's other 48x48 notification icons. Real and slightly
# small beats invisible and technically full-size.
volume_icon() {
    local pct="$1"
    if [ "$pct" -eq 0 ]; then
        echo "/usr/share/icons/Papirus/32x32/status/audio-volume-muted.svg"
    elif [ "$pct" -lt 34 ]; then
        echo "/usr/share/icons/Papirus/32x32/status/audio-volume-low.svg"
    elif [ "$pct" -lt 67 ]; then
        echo "/usr/share/icons/Papirus/32x32/status/audio-volume-medium.svg"
    else
        echo "/usr/share/icons/Papirus/32x32/status/audio-volume-high.svg"
    fi
}

adjust_volume() {
    # $1 like "+5%" or "-5%" (as passed by sway/waybar bindings)
    (
        flock -x 9
        current=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n 1)
        [ -z "$current" ] && current=100
        delta="${1%%%}"
        delta="${delta#+}"
        target=$((current + delta))
        [ "$target" -lt 0 ] && target=0
        [ "$target" -gt 100 ] && target=100
        pactl set-sink-volume @DEFAULT_SINK@ "${target}%"
    ) 9>"$LOCK"
}

if [ "$1" = "mute-toggle" ]; then
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    if pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes; then
        notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$(volume_icon 0)" "Volume" "Muted"
    else
        percentage=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n 1)
        [ -n "$percentage" ] && notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -h int:value:"$percentage" -i "$(volume_icon "$percentage")" "Volume" "${percentage}%"
    fi
    exit 0
fi

# Raising/lowering should always be audible, so drop mute first.
pactl set-sink-mute @DEFAULT_SINK@ 0

adjust_volume "$1"

# Extract the new volume percentage
percentage=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n 1)

# Fire the notification with a progress bar
[ -n "$percentage" ] && notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -h int:value:"$percentage" -i "$(volume_icon "$percentage")" "Volume" "${percentage}%"
