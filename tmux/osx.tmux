#!/bin/bash

source $HOME/.dotfiles/tmux/shared.sh
{
  read -r batteryState
  read -r batteryValue
} <<< "$(source $HOME/.dotfiles/tmux/battery.osx.sh)"


update_tmux_option "status-left" "\#{battery}" "$batteryValue"
update_tmux_option "status-left" "\#{network}" ""


