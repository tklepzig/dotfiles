#!/usr/bin/env zsh

pwd="$1"
name="$2"
mode="$3"
pwd=${pwd/#$HOME/\~};

if [[ -n $name ]]
then
    label="$name"
else
    label="$(basename "$pwd")"
fi

if [[ "$mode" == "short" && ${#label} -gt 3 ]]
then
    echo "${label:0:3}…"
else
    echo "$label"
fi

