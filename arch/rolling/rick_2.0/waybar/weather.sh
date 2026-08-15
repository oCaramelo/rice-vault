#!/usr/bin/env bash
# Outputs JSON {"text":..., "tooltip":...} for waybar custom/weather (return-type json)
# Uses wttr.in with automatic IP-based location, no extra dependencies (curl only).

raw=$(curl -s -m 5 "https://wttr.in/?format=%t|%l:+%C,+feels+like+%f,+humidity+%h" 2>/dev/null)

if [ -z "$raw" ]; then
    printf '{"text":" N/A","tooltip":"Weather unavailable"}\n'
    exit 0
fi

text="${raw%%|*}"
tooltip="${raw#*|}"

text=$(printf '%s' "$text" | tr -d '\n' | tr -s ' ' | sed -e 's/^ //' -e 's/^+//' -e 's/"/\\"/g')
tooltip=$(printf '%s' "$tooltip" | tr -d '\n' | tr -s ' ' | sed -e 's/^ //' -e 's/"/\\"/g')

printf '{"text":"%s","tooltip":"%s"}\n' "$text" "$tooltip"
