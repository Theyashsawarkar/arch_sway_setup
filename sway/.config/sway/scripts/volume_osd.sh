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
# desktop (different icon per range, not one static speaker glyph) --
# names confirmed present in the installed Adwaita icon theme first
# (find /usr/share/icons/Adwaita -iname '*volume*'), same discipline as
# verifying a Nerd Font codepoint exists before using it.
volume_icon() {
    local pct="$1"
    if [ "$pct" -eq 0 ]; then
        echo "audio-volume-muted-symbolic"
    elif [ "$pct" -lt 34 ]; then
        echo "audio-volume-low-symbolic"
    elif [ "$pct" -lt 67 ]; then
        echo "audio-volume-medium-symbolic"
    else
        echo "audio-volume-high-symbolic"
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
        notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i audio-volume-muted-symbolic "Volume" "Muted"
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
