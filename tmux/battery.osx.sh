#!/bin/bash

pmsetString=$(pmset -g batt | egrep "([0-9]+)\%; (.*?); " -o)
value=$(echo $pmsetString | cut -f1 -d'%' | xargs)
mode=$(echo $pmsetString | cut -f2 -d';' | xargs)

color="#[fg=colour7,bg=colour23]"
if [[ "$mode" = "charging" ]]
then
    color="#[fg=colour15,bg=colour22]"
elif [[ $value -lt 16 ]]
then
    color="#[fg=colour15,bg=colour196,bold]"
elif [[ $value -lt 31 ]]
then
    color="#[fg=colour0,bg=colour220,bold]"
fi

echo "$color $value%"
