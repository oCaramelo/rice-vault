#!/usr/bin/env bash
# Sends a desktop notification with today + next 2 days' forecast.
# Triggered by clicking the waybar weather module. Needs jq.

data=$(curl -s -m 5 "https://wttr.in/?format=j1" 2>/dev/null)
location=$(curl -s -m 5 "https://wttr.in/?format=%l" 2>/dev/null)

if [ -z "$data" ]; then
    notify-send -i weather-clear "Weather" "Forecast unavailable"
    exit 0
fi

body=$(printf '%s' "$data" | jq -r '
    [.weather[] | "\(.date): \(.hourly[4].weatherDesc[0].value), \(.mintempC)°C – \(.maxtempC)°C"]
    | join("\n")
')

notify-send -i weather-clear "Weather – ${location}" "$body"
