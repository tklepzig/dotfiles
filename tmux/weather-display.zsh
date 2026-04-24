#!/usr/bin/env zsh

cache_file="/tmp/tmux_weather_cache"
cache_ttl=600

if [[ ! -f "$cache_file" ]] || [[ $(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0) )) -ge $cache_ttl ]]; then
    (curl -s --max-time 5 "wttr.in/?format=%c|%t" 2>/dev/null > "${cache_file}.tmp" && mv "${cache_file}.tmp" "$cache_file" &)
fi

if [[ ! -f "$cache_file" ]]; then
    exit
fi

weather=$(< "$cache_file")

if [[ -z "$weather" ]] || [[ "$weather" == *"nknown"* ]]; then
    exit
fi

icon="${${weather%%|*}// /}"
temp="${${weather##*|}//+/}"

temperature_number="${temp//[^-0-9]/}"

if [[ -z "$temperature_number" ]]; then
    temperature_color="$statusDateTimeFg"
elif (( temperature_number < -5 )); then
    temperature_color="colour33"
elif (( temperature_number < 5 )); then
    temperature_color="colour39"
elif (( temperature_number < 12 )); then
    temperature_color="colour45"
elif (( temperature_number < 18 )); then
    temperature_color="$statusDateTimeFg"
elif (( temperature_number < 24 )); then
    temperature_color="colour214"
elif (( temperature_number < 30 )); then
    temperature_color="colour208"
else
    temperature_color="colour196"
fi

echo "#[fg=$temperature_color] $icon $temp#[default]"
