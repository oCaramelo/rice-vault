#!/usr/bin/env bash
# Outputs JSON {"text":..., "tooltip":...} for waybar custom/weather (return-type json)
# Uses ipinfo.io for IP-based location and open-meteo.com for weather data
# (wttr.in was returning stale/wrong readings for this location).
# Needs curl and jq.

geo=$(curl -s -m 5 "https://ipinfo.io/json" 2>/dev/null)
loc=$(printf '%s' "$geo" | jq -r '.loc // empty')
city=$(printf '%s' "$geo" | jq -r '.city // empty')
region=$(printf '%s' "$geo" | jq -r '.region // empty')

if [ -z "$loc" ]; then
    printf '{"text":" N/A","tooltip":"Weather unavailable"}\n'
    exit 0
fi

lat="${loc%,*}"
lon="${loc#*,}"

data=$(curl -s -m 5 "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code&timezone=auto" 2>/dev/null)

if [ -z "$data" ]; then
    printf '{"text":" N/A","tooltip":"Weather unavailable"}\n'
    exit 0
fi

result=$(printf '%s' "$data" | jq -rc --arg city "$city" --arg region "$region" '
    def wdesc:
        {
            "0":  "Clear sky",
            "1":  "Mainly clear",
            "2":  "Partly cloudy",
            "3":  "Overcast",
            "45": "Fog", "48": "Fog",
            "51": "Light drizzle", "53": "Drizzle", "55": "Dense drizzle",
            "56": "Freezing drizzle", "57": "Freezing drizzle",
            "61": "Slight rain", "63": "Rain", "65": "Heavy rain",
            "66": "Freezing rain", "67": "Freezing rain",
            "71": "Slight snow", "73": "Snow", "75": "Heavy snow",
            "77": "Snow grains",
            "80": "Rain showers", "81": "Rain showers", "82": "Violent rain showers",
            "85": "Snow showers", "86": "Snow showers",
            "95": "Thunderstorm", "96": "Thunderstorm w/ hail", "99": "Thunderstorm w/ hail"
        }[(.current.weather_code | tostring)] // "Unknown";
    (wdesc) as $desc |
    {
        text: ((.current.temperature_2m | round | tostring) + "°C"),
        tooltip: ($city + ", " + $region + ": " + $desc
            + ", feels like " + (.current.apparent_temperature | round | tostring) + "°C"
            + ", humidity " + (.current.relative_humidity_2m | tostring) + "%")
    }
')

if [ -z "$result" ]; then
    printf '{"text":" N/A","tooltip":"Weather unavailable"}\n'
    exit 0
fi

printf '%s\n' "$result"
