#!/usr/bin/env zsh

routeResult=$(route get google.de 2>&1)

if [[ "$routeResult" == *"bad address"* ]]
then
    echo "#[default] #[fg=$secondaryFg,bg=$secondaryBg] Offline #[default] "
else
    interface=$(echo "$routeResult" | grep interface | awk '{print $2}')

    if [[ "$interface" == *"utun"* ]]
    then
        echo "#[default] #[fg=$secondaryFg,bg=$secondaryBg] VPN #[default] "
    else
        device=$(networksetup -listnetworkserviceorder | grep $interface | sed -E -n 's/.*: (.*),.*/\1/p')
        echo "#[default] #[fg=$secondaryFg,bg=$secondaryBg] $device #[default] "
    fi
fi

