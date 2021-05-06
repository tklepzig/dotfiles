#!/usr/bin/env bash

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

blubb="#($currentDir/tmux-test.sh)"
placeholder="\#{blubb}"

currentStatusLeft="$(tmux show-option -gqv "status-left")"
tmux set-option -gq "status-left" "${currentStatusLeft/$placeholder/$blubb}"


