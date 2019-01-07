#!/bin/bash

dotfilesDir='~/.dotfiles'
isOS()
{
    shopt -s nocasematch
    if [[ "$OSTYPE" == *"$1"* ]]
    then
        return 0;
    fi

    return 1;
}

alias mkcd='function __mkcd() { mkdir "$1"; cd "$1"; unset -f __mkcd; }; __mkcd'

if isOS darwin
then
    alias ls='ls -FG'
else
    alias ls='ls -F --color=auto'
fi

alias la='ls -A'
alias ll='ls -lh'
alias lla='ls -Ahl'
alias rmr='rm -rf'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
export PROMPT_DIRTRIM=4
shopt -s extglob

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

if ! isOS darwin
then
    shopt -s globstar
fi

alias sif="$dotfilesDir/search-in-files.sh"
alias hgrep="$dotfilesDir/hgrep.sh"
alias update-my-config='curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/install.sh|bash'
alias update-my-config-skip-vsc='curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/install.sh | bash -s -- --skip-vsc'

_complete_ssh_hosts ()
{
    local cur
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	comp_ssh_hosts=`awk '{split($1,aliases,","); if (aliases[1] !~ /^\[/) print aliases[1]}' ~/.ssh/known_hosts ; cat ~/.ssh/config | grep ^Host  | awk '{print $2}'`
	COMPREPLY=( $(compgen -W "${comp_ssh_hosts}" -- $cur))
	return 0
}
complete -F _complete_ssh_hosts ssh

_complete_rake_tasks ()
{
    local cur
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
    taskCompletion=`rake -T -A | awk '{print $2}'`
	COMPREPLY=( $(compgen -W "${taskCompletion}" -- $cur))
	return 0
}
complete -F _complete_rake_tasks rake

if isOS linux
then
    alias n='nautilus .'
fi

if isOS darwin
then
    alias o='open .'
fi

alias git='LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 git'
alias g='git'
alias gk='LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 gitk --all &'
alias gg='LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 git gui &'
alias gsa="$dotfilesDir/git-status-all.sh"
alias c='code-insiders .'

export GIT_PS1_SHOWDIRTYSTATE=1
export PS1='\u@\h:\[\033[0;33m\]\w\[\033[01;32m\]`__git_ps1`\[\033[00m\]\n\$ '

if isOS linux
then
	[ -f /usr/share/bash-completion/completions/git ] && . /usr/share/bash-completion/completions/git
fi

if isOS darwin
then
    [ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
fi

__git_complete "g s" _git_status
__git_complete "g si" _git_status
__git_complete "g sa" _git_status
__git_complete "g dt" _git_difftool
__git_complete "g dts" _git_difftool
__git_complete "g d" _git_diff
__git_complete "g ds" _git_diff
__git_complete "g l" _git_log
__git_complete "g ll" _git_log
__git_complete "g lm" _git_log
__git_complete "g ln" _git_log
__git_complete "g lp" _git_log
__git_complete "g ld" _git_log
__git_complete "g ls" _git_log
__git_complete "g lf" _git_log
__git_complete "g lfp" _git_log
__git_complete "g rl" _git_reflog
__git_complete "g rll" _git_reflog
__git_complete "g r" _git_reset
__git_complete "g rh" _git_reset
__git_complete "g rs" _git_reset
__git_complete "g a" _git_add
__git_complete "g ap" _git_add
__git_complete "g cm" _git_commit
__git_complete "g cma" _git_commit
__git_complete "g p" _git_push
__git_complete "g pn" _git_push
__git_complete "g c" _git_checkout
__git_complete "g cb" _git_checkout
__git_complete "g b" _git_branch
__git_complete "g bd" _git_branch
__git_complete "g ba" _git_branch
__git_complete "g bnm" _git_branch
__git_complete "g bv" _git_branch
__git_complete "g bc" _git_branch
__git_complete "g f" _git_fetch
__git_complete "g m" _git_merge
__git_complete "g ma" _git_merge
__git_complete "g mff" _git_merge
__git_complete "g mr" _git_merge
__git_complete "g mt" _git_mergetool
__git_complete "g rb" _git_rebase
__git_complete "g rbc" _git_rebase
__git_complete "g rba" _git_rebase
__git_complete "g sw" _git_show
__git_complete "g swn" _git_show
__git_complete "g st" _git_stash
__git_complete "g stp" _git_stash
__git_complete "g stl" _git_stash
__git_complete "g sta" _git_stash
__git_complete "g sts" _git_stash
__git_complete "g t" _git_tag
__git_complete "g td" _git_tag
__git_complete "g tl" _git_tag
__git_complete "g wta" _git_worktree
__git_complete "g wtp" _git_worktree
__git_complete "g wtl" _git_worktree
__git_complete "g cp" _git_cherry_pick
__git_complete "g cpn" _git_cherry_pick
__git_complete "g rv" _git_revert
__git_complete "g rvn" _git_revert
__git_complete g __git_main
