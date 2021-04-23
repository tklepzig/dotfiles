#!/bin/bash

pmsetString=$(pmset -g batt | egrep "([0-9]+)\%; (.*?); " -o)
value=$(echo $pmsetString | cut -f1 -d'%' | xargs)
mode=$(echo $pmsetString | cut -f2 -d';' | xargs)

if [[ "$mode" = "charging" ]]
then
    echo "#[fg=colour76]$value%"
elif [[ $value -lt 16 ]]
then
    echo "#[fg=colour196]$value%"
elif [[ $value -lt 31 ]]
then
    echo "#[fg=colour220]$value%"
else
    echo "$value%"
fi
