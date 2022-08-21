#!/usr/bin/env zsh

tmux set -g status off
while true
do
  echo -ne "\e]12;black\a"
  echo -ne ""

  if read -k1 -s -t 1
  then
    break
  fi  
done
tmux set -g status on
