#!/usr/bin/env bash
# Switch to the next/previous workspace. Works around a Waybar bug where
# hyprland/workspaces' built-in click/scroll dispatch uses the old
# hyprctl text protocol, which Hyprland's Lua dispatcher rejects.
# See: https://github.com/Alexays/Waybar/issues/5008

step="$1" # +1 or -1

current=$(hyprctl activeworkspace -j | jq '.id')
target=$((current + step))
if [ "$target" -lt 1 ]; then
    target=1
fi

hyprctl dispatch "hl.dsp.focus({ workspace = $target })" >/dev/null
