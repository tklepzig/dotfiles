#!/usr/bin/env zsh

rssi=$(system_profiler SPAirPortDataType 2>/dev/null | awk '/Current Network Information/{found=1} found && /Signal \/ Noise/{gsub(/[^-0-9 ]/, ""); print $1; exit}')

if [[ -z "$rssi" || ! "$rssi" =~ ^-?[0-9]+$ ]]; then
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
