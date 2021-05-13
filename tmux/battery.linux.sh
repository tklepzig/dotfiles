#!/usr/bin/env zsh

lcarsDefaultBg=colour172
lcarsDefaultLightBg=colour179
lcarsDefaultLighterBg=colour222
lcarsDefaultFg=colour0
lcarsAccentBg=colour32
lcarsAccentFg=colour15

if [[ -f /sys/class/power_supply/BAT0/uevent ]]
then
  info=$(cat /sys/class/power_supply/BAT0/uevent)
  value=$(echo $info | sed -En "s/^.*POWER_SUPPLY_CAPACITY=([0-9]+).*$/\1/p")
  mode=$(echo $info | sed -En "s/^.*POWER_SUPPLY_STATUS=(.*)$/\1/p")

  color="#[fg=$lcarsDefaultFg,bg=$lcarsDefaultLighterBg]"
  if [[ "$mode" = "Charging" ]]
  then
    color="#[fg=$lcarsDefaultFg,bg=$lcarsDefaultBg]"
  elif [[ $value -lt 16 ]]
  then
    if [[ "$(($(date '+%s') % 3))" = "1" ]]
    then
      color="#[fg=colour196,bg=terminal,bold]"
    else
      color="#[fg=$lcarsAccentFg,bg=colour196,bold]"
    fi
  elif [[ $value -lt 31 ]]
  then
    color="#[fg=$lcarsDefaultFg,bg=colour220,bold]"
  fi

  echo "$color $value%"
fi
