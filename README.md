# dotfiles

My dotfiles for git, zsh, tmux and vim.

## Installation

    curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/install.sh \
    | bash -s -- --profiles=[comma separated list of profiles, see below]

## Profiles

Add these via `--profiles=`, e.g. `--profiles=web,python`

| Name    | Details                    |
| ------- | -------------------------- |
| dev     | Development in General     |
| web     | Web Development            |
| python  | Python Support             |
| ruby    | Ruby Support               |
| writing | Distraction free writing   |
| viml    | VimL/Vimscript Development |

## Complete system setup including dotfiles

    curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/install.system.sh | bash -s
