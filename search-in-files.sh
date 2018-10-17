#!/bin/bash
pattern="*"
[[ ! -z $2 ]] && pattern="$2"
echo -e "Searching for \033[1;33m\"$1\"\033[0m in current directory matching files \033[1;33m\"$pattern\"\033[0m"
find . -type f -name "$pattern" -print0 | xargs -I {} -0 grep -H --color "$1" "{}"
