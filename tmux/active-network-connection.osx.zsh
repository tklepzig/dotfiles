#!/usr/bin/env zsh

routeResult=$(route get google.de 2>&1)

if [[ "$routeResult" == *"bad address"* ]]
then
    echo "#[default] #[fg=$primaryFg,bg=$primaryBg] Offline "
else
    interface=$(echo "$routeResult" | grep interface | awk '{print $2}')

    if [[ "$interface" == *"utun"* ]]
    then
        echo "#[default] #[fg=$primaryFg,bg=$primaryBg] VPN "
    else
        device=$(networksetup -listnetworkserviceorder | grep $interface | sed -E -n 's/.*: (.*),.*/\1/p')
        echo "#[default] #[fg=$primaryFg,bg=$primaryBg] $device "
    fi
fi

