#!/usr/bin/env zsh

maxdepth=${1-1}
find . -maxdepth $maxdepth -mindepth 0 -type d -exec sh -c "test -d \"{}/.git\" && cd \"{}\" && git fetch" \;
