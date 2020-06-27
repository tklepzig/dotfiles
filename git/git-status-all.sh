#!/bin/bash
maxdepth=${1-1}
find . -maxdepth $maxdepth -mindepth 0 -type d -exec sh -c "test -d \"{}/.git\" && (echo \"--------------------------------\" && echo \"{}\" && cd \"{}\" && git status -sb && echo && echo \"Branches:\" && git branch -vv --color && echo && echo)" \; | less -R
