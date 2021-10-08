#!/usr/bin/env zsh

{
    read -r state
    read -r value
} <<< "$(source $HOME/.dotfiles/tmux/free-space.sh)"

color="#[fg=$primaryFg,bg=$primaryLightBg]"
if [[ "$state" = "warning" ]]
then
    color="#[fg=$warningFg,bg=$warningBg,bold]"
elif [[ "$state" = "critical" ]]
then
    if [[ "$(($(date '+%s') % 3))" = "1" ]]
    then
        color="#[fg=$criticalBg,bg=terminal,bold]"
    else
        color="#[fg=$criticalFg,bg=$criticalBg,bold]"
    fi
fi

echo "$color $value"

