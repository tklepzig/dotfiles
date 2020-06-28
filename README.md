# dotfiles

My dotfiles for zsh, tmux and vim.

## Installation

    curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/install.sh \
    | bash -s --profiles=[comma separated list of profiles, see below]

## Profiles

Add these via `--profiles=`, e.g. `--profiles=web,python`

Name|Details
-|-
basic|todo
extended|todo

## Complete system setup including dotfiles

    curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/system-setup/install.sh | bash -s
