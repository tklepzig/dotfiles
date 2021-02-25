#!/usr/bin/env zsh

if [[ -f /sys/class/power_supply/BAT0/uevent ]]
then
  value=$(cat /sys/class/power_supply/BAT0/uevent | sed -En "s/^.*POWER_SUPPLY_CAPACITY=([0-9]+).*$/\1/p")
  if [[ $value -lt 16 ]]
  then
    echo "#[fg=colour196]$value%"
  else
    echo "$value%"
  fi
fi
