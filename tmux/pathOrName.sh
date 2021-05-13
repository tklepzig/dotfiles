#!/usr/bin/env zsh

pwd="$1"
name="$2"
pwd=${pwd/#$HOME/\~};

if [[ -n $name ]]
then
    echo "$name"
else
    echo "$(basename "$pwd")"
fi

