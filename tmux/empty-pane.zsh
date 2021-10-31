#!/usr/bin/env zsh

while true
do
  echo -ne "\e]12;black\a"
  echo -ne ""

  if read -k1 -s -t 1
  then
    break
  fi  
done

