#!/usr/bin/env zsh

{
    read -r state
    read -r value
} <<< "$(source $HOME/.dotfiles/tmux/free-space.zsh)"

color="#[fg=$secondaryText]"
if [[ "$state" = "warning" ]]
then
    color="#[fg=$warningBg,bold]"
elif [[ "$state" = "critical" ]]
then
    if [[ "$(tmux show-environment -gh FREESPACE_BLINK 2>/dev/null)" = "FREESPACE_BLINK=1" ]]; then
        tmux set-environment -gh FREESPACE_BLINK 0
        color="#[fg=$criticalBg,bold]"
    else
        tmux set-environment -gh FREESPACE_BLINK 1
        color="#[bg=$criticalBg,bold]"
    fi
fi

echo "$color $value"

