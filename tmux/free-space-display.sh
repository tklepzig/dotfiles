#!/usr/bin/env zsh

lcarsDefaultBg=colour172
lcarsDefaultLightBg=colour179
lcarsDefaultLighterBg=colour222
lcarsDefaultFg=colour0
lcarsAccentBg=colour32
lcarsAccentFg=colour15

{
    read -r state
    read -r value
} <<< "$(source $HOME/.dotfiles/tmux/free-space.sh)"

color="#[fg=$lcarsDefaultFg,bg=$lcarsDefaultLightBg]"
if [[ "$state" = "warning" ]]
then
    color="#[fg=$lcarsDefaultFg,bg=colour220,bold]"
elif [[ "$state" = "critical" ]]
then
    if [[ "$(($(date '+%s') % 3))" = "1" ]]
    then
        color="#[fg=colour196,bg=terminal,bold]"
    else
        color="#[fg=$lcarsAccentFg,bg=colour196,bold]"
    fi
fi

echo "$color $value"

