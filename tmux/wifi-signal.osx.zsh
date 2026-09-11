#!/usr/bin/env zsh

# macOS 26 zeroes rssiValue() for seconds while still associated; exit 1 then so
# callers hold the last level instead of flapping to "disconnected".
probe=$(swift -e 'import CoreWLAN
if let interface = CWWiFiClient.shared().interface() {
    print(interface.rssiValue())
    print(Int(interface.transmitRate()))
    print(interface.wlanChannel()?.channelNumber ?? 0)
}' 2>/dev/null)

{
    read -r rssi
    read -r transmit_rate
    read -r channel
} <<< "$probe"

# Strict on purpose: a loose test would never report a real disconnect.
associated() {
    [[ "$rssi" =~ ^-?[0-9]+$ ]] || return 1
    (( channel > 0 && transmit_rate > 0 ))
}

if ! associated; then
    echo "disconnected"
    echo ""
    exit 0
fi

if (( rssi == 0 )); then
    exit 1
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
