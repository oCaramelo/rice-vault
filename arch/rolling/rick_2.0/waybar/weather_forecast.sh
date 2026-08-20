#!/usr/bin/env bash
# Sends a desktop notification with today + next 2 days' forecast.
# Triggered by clicking the waybar weather module.
# Uses ipinfo.io for IP-based location and open-meteo.com for weather data.
# Needs curl and jq.

geo=$(curl -s -m 5 "https://ipinfo.io/json" 2>/dev/null)
loc=$(printf '%s' "$geo" | jq -r '.loc // empty')
city=$(printf '%s' "$geo" | jq -r '.city // empty')
region=$(printf '%s' "$geo" | jq -r '.region // empty')

if [ -z "$loc" ]; then
    notify-send -i weather-clear "Weather" "Forecast unavailable"
    exit 0
fi

lat="${loc%,*}"
lon="${loc#*,}"

data=$(curl -s -m 5 "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=3" 2>/dev/null)

if [ -z "$data" ]; then
    notify-send -i weather-clear "Weather" "Forecast unavailable"
    exit 0
fi

body=$(printf '%s' "$data" | jq -r '
    def wdesc:
        {
            "0": "Clear sky", "1": "Mainly clear", "2": "Partly cloudy", "3": "Overcast",
            "45": "Fog", "48": "Fog",
            "51": "Light drizzle", "53": "Drizzle", "55": "Dense drizzle",
            "56": "Freezing drizzle", "57": "Freezing drizzle",
            "61": "Slight rain", "63": "Rain", "65": "Heavy rain",
            "66": "Freezing rain", "67": "Freezing rain",
            "71": "Slight snow", "73": "Snow", "75": "Heavy snow", "77": "Snow grains",
            "80": "Rain showers", "81": "Rain showers", "82": "Violent rain showers",
            "85": "Snow showers", "86": "Snow showers",
            "95": "Thunderstorm", "96": "Thunderstorm w/ hail", "99": "Thunderstorm w/ hail"
        }[(. | tostring)] // "Unknown";
    [range(0; .daily.time | length) as $i |
        "\(.daily.time[$i]): \(.daily.weather_code[$i] | wdesc), \(.daily.temperature_2m_min[$i] | round)°C – \(.daily.temperature_2m_max[$i] | round)°C"
    ] | join("\n")
')

notify-send -i weather-clear "Weather – ${city}, ${region}" "$body"
