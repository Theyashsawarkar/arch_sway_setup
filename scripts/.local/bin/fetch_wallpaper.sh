#!/usr/bin/env bash
# Fetches a new daily wallpaper, validates it, and applies it via sway.
#
# Designed to never leave sway without a usable background and never hand
# swaybg anything unvalidated: checks network connectivity first, retries the
# download, verifies the result is actually an image (not an API error page
# saved as .jpg), and falls back to the last known-good wallpaper -- or, if
# there isn't one yet, a plain solid color -- rather than ever applying
# something that could crash swaybg.
#
# Logs to $LOG_FILE (also visible via `journalctl --user -u wallpaper.service`
# when run from the timer).

set -uo pipefail
# Deliberately not `-e`: this script must always be able to reach its own
# fallback logic, never die partway through on an unexpected error.

BASE_DIR="$HOME/Pictures/Wallpapers"
ACTIVE_DIR="$BASE_DIR/Active"
ARCHIVE_DIR="$BASE_DIR/Archive"
CURRENT="$BASE_DIR/current.jpg"
LAST_GOOD="$BASE_DIR/.last_good.jpg"
LOCK_FILE="/tmp/fetch_wallpaper.lock"
LOG_DIR="$HOME/.local/state/fetch-wallpaper"
LOG_FILE="$LOG_DIR/fetch-wallpaper.log"
LOG_MAX_BYTES=1048576
FALLBACK_COLOR="1e1e2e"  # Catppuccin Mocha base -- last resort if there is no
                          # good wallpaper on disk at all (e.g. brand-new
                          # machine, first run ever, no network yet)
WALLPAPER_URL="https://bing.biturl.top/?resolution=1920&format=image&index=0&mkt=en-US"
MAX_RETRIES=3
RETRY_DELAY=5

mkdir -p "$ACTIVE_DIR" "$ARCHIVE_DIR" "$LOG_DIR"

log() {
  local level="$1"; shift
  printf '[%s] [%s] %s\n' "$(date -Iseconds)" "$level" "$*" | tee -a "$LOG_FILE" >&2
}

# Simple size-based log rotation -- keep one previous log, nothing unbounded.
if [ -f "$LOG_FILE" ] && [ "$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)" -gt "$LOG_MAX_BYTES" ]; then
  mv -f "$LOG_FILE" "$LOG_FILE.old"
fi

# Don't let the timer and a manual run stomp on each other.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log INFO "another fetch_wallpaper.sh is already running, exiting"
  exit 0
fi

is_valid_image() {
  local f="$1"
  [ -s "$f" ] || return 1
  case "$(file -b --mime-type "$f" 2>/dev/null)" in
    image/*) return 0 ;;
    *) return 1 ;;
  esac
}

apply_background() {
  # $1 = image|color, $2 = path or hex color
  local mode="$1" value="$2" swaysock
  swaysock=$(ls /run/user/"$(id -u)"/sway-ipc.*.sock 2>/dev/null | head -n1)
  if [ -z "$swaysock" ]; then
    log WARN "no sway IPC socket found -- not applying live (sway's own 'output * bg' config line will use current.jpg on next start/reload)"
    return 1
  fi
  export SWAYSOCK="$swaysock"
  if [ "$mode" = "image" ]; then
    swaymsg "output * bg '$value' fill" >/dev/null 2>&1
  else
    swaymsg "output * bg $value solid_color" >/dev/null 2>&1
  fi
}

use_fallback() {
  log WARN "falling back: $1"
  if is_valid_image "$LAST_GOOD"; then
    ln -sf "$LAST_GOOD" "$CURRENT"
    if apply_background image "$CURRENT"; then
      log INFO "applied last known-good wallpaper ($LAST_GOOD)"
    fi
  else
    log WARN "no last known-good wallpaper on disk yet either -- using a solid color"
    if apply_background color "$FALLBACK_COLOR"; then
      log INFO "applied solid-color fallback (#$FALLBACK_COLOR)"
    fi
  fi
}

# --- Network check ---------------------------------------------------------
# Cheap pre-check to skip a doomed download outright; the real download's own
# timeouts below are the authoritative check regardless of what this says.
if command -v nmcli >/dev/null 2>&1; then
  connectivity=$(nmcli networking connectivity check 2>/dev/null || echo unknown)
  log INFO "network connectivity: $connectivity"
  if [ "$connectivity" = "none" ]; then
    use_fallback "no network connectivity"
    exit 0
  fi
fi

# --- Download, with retries and real validation -----------------------------
FILEPATH="$ACTIVE_DIR/wallpaper-$(date +%Y%m%d).jpg"
TMP_FILE=$(mktemp "$ACTIVE_DIR/.download.XXXXXX")
downloaded=false

for attempt in $(seq 1 "$MAX_RETRIES"); do
  log INFO "download attempt $attempt/$MAX_RETRIES"
  if curl -fsSL --connect-timeout 10 --max-time 20 -o "$TMP_FILE" "$WALLPAPER_URL"; then
    if is_valid_image "$TMP_FILE"; then
      downloaded=true
      break
    fi
    log WARN "attempt $attempt: response wasn't an image (got $(file -b --mime-type "$TMP_FILE" 2>/dev/null || echo unknown)) -- API is up but returned something unusable, discarding"
  else
    log WARN "attempt $attempt: download failed (curl exit $?)"
  fi
  [ "$attempt" -lt "$MAX_RETRIES" ] && sleep "$RETRY_DELAY"
done

if [ "$downloaded" != true ]; then
  rm -f "$TMP_FILE"
  use_fallback "no valid image after $MAX_RETRIES attempts"
  exit 0
fi

# --- Success: archive the old one, promote the new one ---------------------
log INFO "download OK: $(file -b --mime-type "$TMP_FILE"), $(stat -c%s "$TMP_FILE") bytes"

find "$ACTIVE_DIR" -maxdepth 1 -type f ! -name "$(basename "$TMP_FILE")" -exec mv -t "$ARCHIVE_DIR" {} + 2>/dev/null

mv -f "$TMP_FILE" "$FILEPATH"
chmod 644 "$FILEPATH"
cp -f "$FILEPATH" "$LAST_GOOD"
ln -sf "$FILEPATH" "$CURRENT"

if apply_background image "$CURRENT"; then
  log INFO "applied new wallpaper: $FILEPATH"
else
  log WARN "couldn't reach sway IPC to apply immediately; current.jpg is updated and will show on next sway start/reload"
fi
