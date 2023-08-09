#!/usr/bin/env zsh

npx --yes http-server ${2:-.} -S -C $1.crt -K $1.key -o
