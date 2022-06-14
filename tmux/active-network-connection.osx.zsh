#!/usr/bin/env zsh

routeResult=$(route get google.de 2>&1)

if [[ "$routeResult" == *"bad address"* ]]
then
    echo "#[fg=$secondaryFg,bg=$secondaryBg] Offline #[default] "
else
    interface=$(echo "$routeResult" | grep interface | awk '{print $2}')

    if [[ "$interface" == *"utun"* ]]
    then
        echo "#[fg=$secondaryFg,bg=$secondaryBg] VPN #[default] "
    else
        device=$(networksetup -listnetworkserviceorder | grep $interface | sed -E -n 's/.*: (.*),.*/\1/p')
        ssid=$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I  | awk -F' SSID: '  '/ SSID: / {print $2}')
        echo "#[fg=$secondaryFg,bg=$secondaryBg] $device ($ssid) #[default] "
    fi
fi

