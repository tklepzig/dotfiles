#!/bin/bash

pmsetString=$(pmset -g batt | egrep "([0-9]+)\%; (.*?); " -o)
value=$(echo $pmsetString | cut -f1 -d'%' | xargs)
mode=$(echo $pmsetString | cut -f2 -d';' | xargs)

modePrefix="discharging"
if [[ "$mode" = "charging" ]]
then
    modePrefix="charging"
elif [[ $value -lt 16 ]]
then
    if [[ "$(($(date '+%s') % 3))" = "1" ]]
    then
        modePrefix="lt16_alt"
    else
        modePrefix="lt16"
    fi
elif [[ $value -lt 31 ]]
then
    modePrefix="lt31"
fi

echo "$modePrefix-$value%"
