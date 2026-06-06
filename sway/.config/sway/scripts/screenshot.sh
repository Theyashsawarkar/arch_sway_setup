#!/bin/bash
# Usage:
#   screenshot.sh        → full screen (default, keeps Print key working)
#   screenshot.sh region → select area with slurp

MODE="${1:-full}"
DIR="$HOME/Pictures/Screenshots"
FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S_screenshot.png')"

mkdir -p "$DIR"

if [[ "$MODE" == "region" ]]; then
  GEOMETRY=$(slurp 2>/dev/null)
  if [[ -z "$GEOMETRY" ]]; then
    notify-send -u low "Screenshot cancelled"
    exit 0
  fi
  grim -g "$GEOMETRY" "$FILE"
else
  grim "$FILE"
fi

wl-copy <"$FILE"
notify-send \
  -h string:x-canonical-private-synchronous:sys-notify \
  -i "$FILE" \
  "Screenshot captured" \
  "Saved and copied to clipboard."
