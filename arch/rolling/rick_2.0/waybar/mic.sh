#!/usr/bin/env bash
# Compact mic status for waybar custom module (return-type json).
# Scroll over the module (on-scroll-up/down in config.jsonc) adjusts source volume.

vol=$(pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null | grep -oP '\d+(?=%)' | head -1)
muted=$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -oP '(?<=Mute: )(yes|no)')

if [ -z "$vol" ]; then
    printf '{"text":"N/A","tooltip":"No microphone found","class":"muted"}\n'
    exit 0
fi

if [ "$muted" = "yes" ]; then
    icon=""
    class="muted"
    state="muted"
else
    icon=""
    class="unmuted"
    state="unmuted"
fi

printf '{"text":"%s%% %s","tooltip":"Mic: %s%% (%s)\\nScroll to change, click to mute","class":"%s"}\n' \
    "$vol" "$icon" "$vol" "$state" "$class"
