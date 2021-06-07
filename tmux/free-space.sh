#!/usr/bin/env zsh

mb=$(($(BLOCKSIZE=512 df / | tail -1 | awk '{print $4}') / 2 / 1024))

if [[ $mb -lt 1 ]]
then
    echo "critical"
    echo "< 1 MB"
    exit
fi

if [[ $mb -lt 1024 ]]
then
    echo "critical"
    echo "$mb MB"
    exit
fi

gb=$(($mb / 1024))
if [[ $gb -lt 10 ]]
then
    echo "warning"
else
    echo "normal"
fi
echo "$gb GB"
