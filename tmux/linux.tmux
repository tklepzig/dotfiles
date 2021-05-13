#!/bin/bash

source $HOME/.dotfiles/tmux/shared.sh

{
  read -r batteryState
  read -r batteryValue
} <<< "$(source $HOME/.dotfiles/tmux/battery.linux.sh)"


update_tmux_option "status-left" "\#{battery}" "$batteryValue"

