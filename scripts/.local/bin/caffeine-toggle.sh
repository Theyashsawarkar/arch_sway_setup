#!/usr/bin/env bash
# Toggles "caffeine mode" by stopping/starting the swayidle user service
# entirely -- no dpms-off, no lock, no suspend while it's stopped.
#
# Deliberately stops swayidle rather than just inhibiting suspend:
# systemd-inhibit-style suspend blocking wouldn't touch
# 'timeout 600 swaymsg output * dpms off' at all, since that's swayidle
# talking to sway directly, never going through logind. Stopping the
# service is the only thing that keeps the screen itself on too.
#
# Uses systemctl --user rather than raw process management (pkill/setsid)
# -- simpler and more reliable than juggling backgrounding/disown by hand.
#
# STATE_FILE persists the on/off choice across reboots -- swayidle.service
# is `enabled` (WantedBy=default.target), so systemd auto-starts it at
# every login on its own regardless of what this script did last;
# swayidle-startup.sh (run from sway/config at startup) reads this same
# file to re-apply whatever was chosen here, rather than caffeine mode
# silently resetting to off on every reboot.
STATE_DIR="$HOME/.local/state/caffeine"
STATE_FILE="$STATE_DIR/enabled"
mkdir -p "$STATE_DIR"

if systemctl --user is-active --quiet swayidle.service; then
    systemctl --user stop swayidle.service
    touch "$STATE_FILE"
    notify-send -i weather-few-clouds-night "Caffeine on" "Screen will stay on, laptop won't sleep or lock until you turn this off"
else
    systemctl --user start swayidle.service
    rm -f "$STATE_FILE"
    notify-send -i weather-clear "Caffeine off" "Screen will dim, lock, and suspend normally again"
fi
