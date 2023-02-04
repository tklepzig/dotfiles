# dotfiles

My dotfiles.

## Installation

    /usr/bin/env ruby -e "$(curl -Ls https://raw.githubusercontent.com/\
    tklepzig/dotfiles/master/setup.rb)"

## Profiles

The following profiles are available:

| Name    | Details                    |
| ------- | -------------------------- |
| dev     | Development in General     |
| web     | Web Development            |
| python  | Python Support             |
| ruby    | Ruby Support               |
| writing | Distraction free writing   |
| viml    | VimL/Vimscript Development |

Add these to the environment variable `DOTFILES_PROFILES` space-separated in your `.zshrc`.  
It must be set before the dotfiles stuff is sourced.  
For example:

    export DOTFILES_PROFILES="dev web"

## asdf setup

     /usr/bin/env zsh -c "$(curl -Ls https://raw.githubusercontent.com/\
     tklepzig/dotfiles/master/asdf.install.sh)"
