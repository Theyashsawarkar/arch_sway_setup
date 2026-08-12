#!/bin/bash
# =============================================================================
# wf-recorder toggle — start or stop recording
# Usage:
#   wf-recorder-toggle.sh full      → records entire screen
#   wf-recorder-toggle.sh region    → prompts to select a region first
# Output lands in ~/Videos/recordings/ with a timestamp filename.
# =============================================================================

MODE="${1:-full}"
RECORDINGS_DIR="$HOME/Videos/recordings"
PIDFILE="/tmp/wf-recorder.pid"

mkdir -p "$RECORDINGS_DIR"

# --- Stop if already recording ---
if [[ -f "$PIDFILE" ]]; then
  pid=$(cat "$PIDFILE")
  if kill -0 "$pid" 2>/dev/null; then
    kill -SIGINT "$pid"
    rm -f "$PIDFILE"
    notify-send -i media-record -u low "Recording stopped" "Saved to $RECORDINGS_DIR"
    exit 0
  else
    # Stale pid file
    rm -f "$PIDFILE"
  fi
fi

# --- Start recording ---
OUTFILE="$RECORDINGS_DIR/$(date +%Y%m%d_%H%M%S).mp4"

if [[ "$MODE" == "region" ]]; then
  GEOMETRY=$(slurp 2>/dev/null)
  if [[ -z "$GEOMETRY" ]]; then
    notify-send -u low "Recording cancelled"
    exit 0
  fi
  wf-recorder --geometry "$GEOMETRY" -f "$OUTFILE" &
else
  wf-recorder -f "$OUTFILE" &
fi

echo $! >"$PIDFILE"
notify-send -i media-record -u low "Recording started" "$OUTFILE"
