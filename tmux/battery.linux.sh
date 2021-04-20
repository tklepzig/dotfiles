#!/usr/bin/env zsh

if [[ -f /sys/class/power_supply/BAT0/uevent ]]
then
  info=$(cat /sys/class/power_supply/BAT0/uevent)
  value=$(echo $info | sed -En "s/^.*POWER_SUPPLY_CAPACITY=([0-9]+).*$/\1/p")
  mode=$(echo $info | sed -En "s/^.*POWER_SUPPLY_STATUS=(.*)$/\1/p")

  if [[ "$mode" = "Charging" ]]
  then
    echo "#[fg=colour76]$value%"
  elif [[ $value -lt 31 ]]
  then
    echo "#[fg=colour220]$value%"
  elif [[ $value -lt 16 ]]
  then
    echo "#[fg=colour196]$value%"
  else
    echo "$value%"
  fi
fi
