#!/usr/bin/env bash
# Reports capslock/numlock state for waybar as JSON (same {text,class,tooltip}
# pattern as caffeine-status.sh/docker-status.sh). Takes "capslock" or
# "numlock" as $1 -- one script, two custom waybar modules, rather than
# duplicating this per key.
#
# Replaces waybar's built-in `keyboard-state` module -- that module has no
# on-click, no tooltip, and no cursor change at all (confirmed: none of those
# are in its documented config schema, man waybar-keyboard-state), so it
# can't be made clickable/hoverable no matter what CSS is thrown at it. A
# custom module can do all three.
#
# Reads the real kernel LED state directly (same source waybar's own
# built-in module reads via libevdev) rather than trusting any cached/
# derived state -- this is genuinely live.
set -uo pipefail

KEY="${1:?usage: keylock-status.sh capslock|numlock}"

case "$KEY" in
    capslock) LED_GLOB="/sys/class/leds/*::capslock/brightness"; LABEL="Caps Lock"; ICON=$''; ICON_OFF=$''; BADGE="A" ;;
    numlock)  LED_GLOB="/sys/class/leds/*::numlock/brightness";  LABEL="Num Lock";  ICON=$''; ICON_OFF=$''; BADGE="#" ;;
    *) echo "unknown key: $KEY" >&2; exit 1 ;;
esac

LED_FILE=$(ls $LED_GLOB 2>/dev/null | head -n1)
if [ -z "$LED_FILE" ]; then
    printf '{"text":"%s %s","class":"unlocked","tooltip":"%s: unknown (no LED device found)"}\n' "$BADGE" "$ICON_OFF" "$LABEL"
    exit 0
fi

STATE=$(cat "$LED_FILE" 2>/dev/null || echo 0)

if [ "$STATE" -gt 0 ]; then
    printf '{"text":"%s %s","class":"locked","tooltip":"%s: On -- click to turn off"}\n' "$BADGE" "$ICON" "$LABEL"
else
    printf '{"text":"%s %s","class":"unlocked","tooltip":"%s: Off -- click to turn on"}\n' "$BADGE" "$ICON_OFF" "$LABEL"
fi
