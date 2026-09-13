#!/usr/bin/env zsh

pwd="$1"
name="$2"
mode="$3"
sshTarget="$4"
pwd=${pwd/#$HOME/\~};

prefix=""

if [[ -n $name ]]
then
    label="$name"
elif [[ -n $sshTarget ]]
then
    prefix="ssh:"
    label="$sshTarget"
else
    label="$(basename "$pwd")"
fi

# Truncate only the label, so the ssh: marker survives short mode.
if [[ "$mode" == "short" && ${#label} -gt 3 ]]
then
    label="${label:0:3}…"
fi

echo "$prefix$label"
