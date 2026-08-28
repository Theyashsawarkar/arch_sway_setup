#!/usr/bin/env bash
# Applies caffeine mode's persisted state at sway startup, run from
# sway/config in place of an unconditional `systemctl --user restart
# swayidle.service`.
#
# Why this exists: swayidle.service is `enabled` (WantedBy=default.target),
# so systemd's user manager auto-starts it at every login on its own,
# completely independent of sway -- caffeine mode (stopping the service)
# never survived a reboot/login because of this, no matter what state it
# was left in before. This script is the single source of truth for what
# swayidle's state should be at this point in startup: if caffeine was on
# (marker file present, written by caffeine-toggle.sh), it stops the
# service systemd just auto-started, overriding that; otherwise it does
# the normal restart -- still needed for the env-var-ordering reason
# documented in sway/config right above this exec line (swayidle started
# by systemd at login can predate dbus-update-activation-environment).
STATE_FILE="$HOME/.local/state/caffeine/enabled"

if [ -e "$STATE_FILE" ]; then
    systemctl --user stop swayidle.service
else
    systemctl --user restart swayidle.service
fi
