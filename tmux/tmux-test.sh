#!/usr/bin/env bash

panePath=$(tmux display-message -p -F "#{pane_current_path}")
cd $panePath

isGitRepo=$(git rev-parse --git-dir 2> /dev/null)
if [[ -n $isGitRepo ]]
then
    branch=$(git rev-parse --abbrev-ref HEAD)
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2> /dev/null)

    if [[ -z $upstream ]]
    then
        upstream_prompt="#";
    else
        upstream_info=$(git rev-list --left-right --count $upstream...HEAD 2> /dev/null)
        case "$upstream_info" in
            "") # no upstream
                upstream_prompt="" ;;
            "0	0") # equal to upstream
                upstream_prompt="=" ;;
            "0	"*) # ahead of upstream
                upstream_prompt=">" ;;
            *"	0") # behind upstream
                upstream_prompt="<" ;;
            *)	    # diverged from upstream
                upstream_prompt="<>" ;;
        esac
    fi

    dirtyState=$(git status --porcelain 2> /dev/null | tail -n1)
    if [[ -n $dirtyState ]]; then
        echo "#[fg=red]$(echo $branch | sed 's/.*\(.\{24\}\)/…\1/') #[fg=cyan]$upstream_prompt#[fg=colour7] | #[default]"
    else
        echo "#[fg=green]$branch #[fg=cyan]$upstream_prompt#[fg=colour7] | #[default]"
    fi
fi
