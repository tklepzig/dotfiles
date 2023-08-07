#!/bin/bash

for i in {0..255} ; do
    name=$(printf "%09s" "colour$i")
    printf "\x1b[38;5;${i}m$name  \x1b[48;5;${i}m $name \e[0m\t"

    if [ $((($i + 1) % ${1-4})) == 0 ]
    then
        printf "\n"
    fi
done
