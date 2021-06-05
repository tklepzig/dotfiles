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
} <<< "$(source $HOME/.dotfiles/tmux/battery.$1.sh)"

if [[ -z $value ]]
then
    echo "#[bg=$lcarsDefaultBg]"
    exit
fi

color="#[fg=$lcarsDefaultFg,bg=$lcarsDefaultLighterBg]"
if [[ "$state" = "charging" ]]
then
    color="#[fg=$lcarsDefaultFg,bg=$lcarsDefaultBg]"
elif [[ $value -lt 16 ]]
then
    if [[ "$(($(date '+%s') % 3))" = "1" ]]
    then
        color="#[fg=colour196,bg=terminal,bold]"
    else
        color="#[fg=$lcarsAccentFg,bg=colour196,bold]"
    fi
elif [[ $value -lt 31 ]]
then
    color="#[fg=$lcarsDefaultFg,bg=colour220,bold]"
fi

echo "$color $value%"

