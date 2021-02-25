#!/bin/bash

routeResult=$(route get google.de 2>&1)

if [[ "$routeResult" == *"bad address"* ]]
then
    echo "#[fg=colour196]Offline"
else
    interface=$(echo "$routeResult" | grep interface | awk '{print $2}')

    if [[ "$interface" == *"utun"* ]]
    then
        echo "#[fg=colour4]VPN"
    else
        device=$(networksetup -listnetworkserviceorder | grep $interface | sed -E -n 's/.*: (.*),.*/\1/p')
        echo "$device"
    fi
fi

