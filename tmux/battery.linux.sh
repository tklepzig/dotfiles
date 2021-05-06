#!/usr/bin/env zsh

if [[ -f /sys/class/power_supply/BAT0/uevent ]]
then
  info=$(cat /sys/class/power_supply/BAT0/uevent)
  value=$(echo $info | sed -En "s/^.*POWER_SUPPLY_CAPACITY=([0-9]+).*$/\1/p")
  mode=$(echo $info | sed -En "s/^.*POWER_SUPPLY_STATUS=(.*)$/\1/p")

  color="#[fg=colour7,bg=colour23]"
  if [[ "$mode" = "Charging" ]]
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
fi
