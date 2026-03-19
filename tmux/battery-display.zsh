#!/usr/bin/env zsh

{
    read -r state
    read -r value
} <<< "$(source $HOME/.dotfiles/tmux/battery.$1.zsh)"

if [[ -z $value ]]
then
    exit
fi

color="#[fg=$secondaryText]"
if [[ "$state" = "charging" ]]
then
    color="#[fg=$accentText]"
elif [[ $value -lt 16 ]]
then
    if [[ "$(tmux show-environment BATTERY_BLINK 2>/dev/null)" = "BATTERY_BLINK=1" ]]; then
        tmux set-environment BATTERY_BLINK 0
        color="#[fg=$criticalBg,bold]"
    else
        tmux set-environment BATTERY_BLINK 1
        color="#[bg=$criticalBg,bold]"
    fi
elif [[ $value -lt 31 ]]
then
    color="#[fg=$warningBg,bold]"
fi

echo "$color $value%"

