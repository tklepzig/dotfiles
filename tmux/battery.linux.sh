#!/usr/bin/env zsh

if [[ -f /sys/class/power_supply/BAT0/uevent ]]
then
  info=$(cat /sys/class/power_supply/BAT0/uevent)
  value=$(echo $info | sed -En "s/^.*POWER_SUPPLY_CAPACITY=([0-9]+).*$/\1/p")
  mode=$(echo $info | sed -En "s/^.*POWER_SUPPLY_STATUS=(.*)$/\1/p")

  modePrefix="discharging"
  if [[ "$mode" = "Charging" ]]
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
fi
