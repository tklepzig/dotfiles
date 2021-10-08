#!/usr/bin/env zsh

if [[ -f /sys/class/power_supply/BAT0/uevent ]]
then
  info=$(cat /sys/class/power_supply/BAT0/uevent)
  value=$(echo $info | sed -En "s/^.*POWER_SUPPLY_CAPACITY=([0-9]+).*$/\1/p")
  state=$(echo $info | sed -En "s/^.*POWER_SUPPLY_STATUS=(.*)$/\1/p")
  state=${state:l}

  echo "$state"
  echo "$value"
fi
