#!/usr/bin/env zsh

{
    read -r state
    read -r value
} <<< "$(source $HOME/.dotfiles/tmux/wifi-signal.$1.zsh)"

if [[ -z "$state" ]]; then
    echo ""
    exit
fi

if [[ "$state" = "disconnected" ]]; then
    echo "#[fg=$infoFg,bg=$infoBg] ⊘"
    exit
fi

if [[ "$state" = "excellent" ]]; then
    bars="▂▄▆█"
    color="#[fg=$primaryFg,bg=$primaryBg]"
elif [[ "$state" = "good" ]]; then
    bars="▂▄▆"
    color="#[fg=$secondaryFg,bg=$secondaryBg]"
elif [[ "$state" = "fair" ]]; then
    bars="▂▄"
    color="#[fg=$warningFg,bg=$warningBg]"
else
    bars="▂"
    color="#[fg=$criticalFg,bg=$criticalBg]"
fi

echo "$color $bars"
