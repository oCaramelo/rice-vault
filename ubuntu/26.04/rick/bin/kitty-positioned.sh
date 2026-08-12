#!/bin/bash

# File that stores which quadrant to use next
STATE_FILE="$HOME/.cache/kitty-quadrant-state"
LOCK_FILE="$HOME/.cache/kitty-quadrant-state.lock"
mkdir -p "$HOME/.cache"

# Get screen resolution automatically
SCREEN_RES=$(xrandr --current | grep '*' | awk '{print $1}' | head -1)
SCREEN_W=$(echo "$SCREEN_RES" | cut -d'x' -f1)
SCREEN_H=$(echo "$SCREEN_RES" | cut -d'x' -f2)

# Read + update the quadrant state atomically, so two fast invocations
# never read the same value at once and desync the sequence
exec 200>"$LOCK_FILE"
flock 200

QUADRANT=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
NEXT=$(( (QUADRANT + 1) % 4 ))
echo $NEXT > "$STATE_FILE"

flock -u 200
exec 200>&-

# Unique title so we can find exactly this window
TITLE="kitty-quad-$$"

# Force X11 backend so wmctrl can move the window.
kitty --title "$TITLE" \
    -o linux_display_server=x11 \
    -o hide_window_decorations=yes \
    -o window_padding_width=10 \
    -o background_color=black &

# Wait until the window actually exists, and grab its real geometry
for i in $(seq 1 20); do
    LINE=$(wmctrl -lG | awk -v t="$TITLE" '$0 ~ t')
    [ -n "$LINE" ] && break
    sleep 0.1
done

if [ -z "$LINE" ]; then
    echo "Error: could not find the kitty window" >&2
    exit 1
fi

WIN_ID=$(echo "$LINE" | awk '{print $1}')
WIN_W=$(echo "$LINE" | awk '{print $5}')
WIN_H=$(echo "$LINE" | awk '{print $6}')

FULL_H=$WIN_H

GRID_W=$((WIN_W * 2))
GRID_H=$((FULL_H * 2))
OFFSET_X=$(( (SCREEN_W - GRID_W) / 2 ))
OFFSET_Y=$(( (SCREEN_H - GRID_H) / 2 ))

case $QUADRANT in
    0) X=$((OFFSET_X + WIN_W)); Y=$OFFSET_Y ;;               # top-right
    1) X=$OFFSET_X;             Y=$OFFSET_Y ;;                # top-left
    2) X=$OFFSET_X;             Y=$((OFFSET_Y + FULL_H)) ;;   # bottom-left
    3) X=$((OFFSET_X + WIN_W)); Y=$((OFFSET_Y + FULL_H)) ;;   # bottom-right
esac

wmctrl -i -r "$WIN_ID" -e 0,$X,$Y,-1,-1