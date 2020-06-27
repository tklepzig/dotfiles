#!/bin/bash
HISTFILE=~/.bash_history
set -o history
history | grep "$1"
