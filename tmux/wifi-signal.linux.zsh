#!/usr/bin/env zsh

rssi=$(iwconfig 2>/dev/null | awk '/Signal level/{match($0, /Signal level=(-?[0-9]+)/, arr); if (arr[1] != "") {print arr[1]; exit}}')

if [[ -z "$rssi" ]]; then
    rssi=$(awk 'NR==3{gsub(/\./, ""); print int($4)}' /proc/net/wireless 2>/dev/null)
fi

if [[ -z "$rssi" ]]; then
    echo "disconnected"
    echo ""
    exit
fi

if [[ $rssi -ge -30 ]]; then
    percent=100
elif [[ $rssi -le -90 ]]; then
    percent=0
else
    percent=$(( (rssi + 90) * 100 / 60 ))
fi

if [[ $percent -ge 70 ]]; then
    state="excellent"
elif [[ $percent -ge 40 ]]; then
    state="good"
elif [[ $percent -ge 20 ]]; then
    state="fair"
else
    state="weak"
fi

echo "$state"
echo "$percent"
