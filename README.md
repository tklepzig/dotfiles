# dotfiles

My dotfiles for git, zsh, tmux and vim.

## Installation

    curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/install.sh \
    | bash -s --profiles=[comma separated list of profiles, see below]

## Profiles

Add these via `--profiles=`, e.g. `--profiles=web,python`

Name|Details
-|-
basic|base profile, already included
dev|nerdtree, git, markdown, ranger, fzf
js|coc, jest
python|python
ruby|ruby
writing|goyo, seoul, limelight
or|zimpl

## Complete system setup including dotfiles

    curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/system-setup/install.sh | bash -s
