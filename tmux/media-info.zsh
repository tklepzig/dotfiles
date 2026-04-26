#!/usr/bin/env zsh

{
    read -r state
    read -r title
} <<< "$(source $HOME/.dotfiles/tmux/media-info.$1.zsh)"

if [[ -z $title ]]
then
    exit
fi

if [[ $state == "Playing" ]]
then
    icon=$(echo -e '▶')
elif [[ $state == "Paused" ]]
then
    icon=$(echo -e '⏸')
elif [[ $state == "Stopped" ]]
then
    icon=$(echo -e '⏹')
else
    icon=""
fi

echo "#[fg=$secondaryText] $icon $title#[default]"
