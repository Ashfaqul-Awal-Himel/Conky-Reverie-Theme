#!/bin/bash
CITY_ID=1857910
API_KEY="6c8a51429110e12df2882dbba1a8b686"
UNIT=metric
LANG=en

CACHE="$HOME/.cache/weather.json"
ICON_FILE="/tmp/conky_wicon"
TEMP_FILE="/tmp/conky_wtemp"
CITY_FILE="/tmp/conky_wcity"
LOG_FILE="/tmp/conky_weather.log"

[[ ! -f "$ICON_FILE" ]] && printf '\UF0590' > "$ICON_FILE"
[[ ! -f "$TEMP_FILE" ]] && echo "--"         > "$TEMP_FILE"
[[ ! -f "$CITY_FILE" ]] && echo "Detecting location..."  > "$CITY_FILE"

curl -sf --max-time 8 \
    "https://api.openweathermap.org/data/2.5/weather?id=${CITY_ID}&appid=${API_KEY}&units=${UNIT}&lang=${LANG}" \
    -o "$CACHE"

CURL_EXIT=$?
echo "=== $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOG_FILE"

if [[ $CURL_EXIT -ne 0 ]] || [[ ! -s "$CACHE" ]]; then
    echo "FETCH FAILED (curl exit $CURL_EXIT)" >> "$LOG_FILE"
    exit 1
fi

# ── Check for API error ───────────────────────────────────
COD=$(jq -r '.cod' "$CACHE" 2>/dev/null)
if [[ "$COD" != "200" ]]; then
    MSG=$(jq -r '.message // "unknown error"' "$CACHE")
    echo "OWM ERROR: cod=$COD msg=$MSG" >> "$LOG_FILE"
    echo "ERR" > "$TEMP_FILE"
    printf '\UF0238' > "$ICON_FILE"
    exit 1
fi

TEMP=$(jq '.main.temp' "$CACHE" | awk '{print int($1+0.5)}')
ICON_CODE=$(jq -r '.weather[0].icon' "$CACHE")
CITY_NAME=$(jq -r '.name' "$CACHE")
DESCRIPTION=$(jq -r '.weather[0].description' "$CACHE")

echo "city=$CITY_NAME | code=$ICON_CODE | desc=$DESCRIPTION | temp=${TEMP}C" >> "$LOG_FILE"

get_icon() {
    case "$1" in
        01d)     printf '\UF0599' ;;  # nf-md-weather_sunny
        01n)     printf '\UF0594' ;;  # nf-md-weather_night
        02d)     printf '\UF0595' ;;  # nf-md-weather_partly_cloudy
        02n)     printf '\UF0F31' ;;  # nf-md-weather_night_partly_cloudy
        03d|03n) printf '\UF0590' ;;  # nf-md-weather_cloudy
        04d|04n) printf '\UF0590' ;;  # nf-md-weather_cloudy
        09d|09n) printf '\UF0F33' ;;  # nf-md-weather_pouring
        10d|10n) printf '\UF0597' ;;  # nf-md-weather_rainy
        11d|11n) printf '\UF0593' ;;  # nf-md-weather_lightning
        13d|13n) printf '\UF0598' ;;  # nf-md-weather_snowy
        50d|50n) printf '\UF0591' ;;  # nf-md-weather_fog
        *)       printf '\UF0238' ;;  # fallback
    esac
}
echo "$TEMP"           > "$TEMP_FILE"
echo "$CITY_NAME"      > "$CITY_FILE"
get_icon "$ICON_CODE"  > "$ICON_FILE"

echo "icon hex: $(xxd < $ICON_FILE | head -1)" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"
