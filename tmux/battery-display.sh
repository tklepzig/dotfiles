#!/usr/bin/env zsh

{
    read -r state
    read -r value
} <<< "$(source $HOME/.dotfiles/tmux/battery.$1.sh)"

if [[ -z $value ]]
then
    echo "#[bg=$primaryBg]"
    exit
fi

color="#[fg=$primaryFg,bg=$primaryLighterBg]"
if [[ "$state" = "charging" ]]
then
    color="#[fg=$primaryFg,bg=$primaryBg]"
elif [[ $value -lt 16 ]]
then
    if [[ "$(($(date '+%s') % 3))" = "1" ]]
    then
        color="#[fg=$criticalBg,bg=terminal,bold]"
    else
        color="#[fg=$criticalFg,bg=$criticalBg,bold]"
    fi
elif [[ $value -lt 31 ]]
then
    color="#[fg=$warningFg,bg=$warningBg,bold]"
fi

echo "$color $value%"

