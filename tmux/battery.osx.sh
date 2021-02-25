#!/bin/bash

value=$(pmset -g batt | egrep "([0-9]+)\%.*" -o --colour=auto | cut -f1 -d';')

if [[ $value -lt 16 ]]
then
    echo "#[fg=colour196]$value"
else
    echo "$value"
fi
