#!/bin/zsh

isOS()
{
  if [[ "$OSTYPE:l" == *"$1:l"* ]]
  then
    return 0;
  fi

  return 1;
}

if isOS darwin
then
  pmset -g batt | egrep "([0-9]+)\%.*" -o --colour=auto | cut -f1 -d'%'
else
  cat /sys/class/power_supply/BAT0/uevent | sed -En "s/^.*POWER_SUPPLY_CAPACITY=([0-9]+).*$/\1/p"
fi
