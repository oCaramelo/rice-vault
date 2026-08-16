#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-full}"
DIR="$HOME/media/screenshots"
mkdir -p "$DIR"
FILE="$DIR/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

case "$MODE" in
  full)
    ACTIVE=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true).name')
    grim -o "$ACTIVE" "$FILE"
    ;;
  area)
    GEOM=$(slurp) || exit 0
    [ -z "$GEOM" ] && exit 0
    grim -g "$GEOM" "$FILE"
    ;;
  *)
    echo "usage: screenshot.sh [full|area]" >&2
    exit 1
    ;;
esac

wl-copy < "$FILE"
notify-send -i "$FILE" "Screenshot guardado" "$FILE"
