#!/usr/bin/env zsh

sensor="$HOME/.dotfiles/tmux/cpu-temp.$1.zsh"
[[ -f "$sensor" ]] || { echo; exit }

{
    read -r state
    read -r value
} <<< "$(source $sensor)"

[[ "$state" = "critical" ]] || { echo; exit }

echo "#[fg=$statusSeparatorFg] │#[default] #[bg=$criticalBg,bold] ${value}°C #[default]"
