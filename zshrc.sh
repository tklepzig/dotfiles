#!/bin/zsh

dotfilesDir="$HOME/.dotfiles"

isOS()
{
    if [[ "$OSTYPE:l" == *"$1:l"* ]]
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

autoload -U colors compinit promptinit
colors
promptinit
compinit

zstyle ':completion:*' menu select

setopt auto_cd
setopt nonomatch

HISTFILE=$HOME/.history
HISTSIZE=10000
SAVEHIST=20000
setopt hist_ignore_all_dups
setopt inc_append_history

# source /usr/lib/git-core/git-sh-prompt
# GIT_PS1_SHOWDIRTYSTATE=1
# GIT_PS1_SHOWSTASHSTATE=1
# GIT_PS1_SHOWUNTRACKEDFILES=1
# GIT_PS1_SHOWUPSTREAM="auto"
# GIT_PS1_SHOWCOLORHINTS=1
# NEWLINE=$'\n'
# precmd () { __git_ps1 "%n@%m:%~" "${NEWLINE}\$ " " (%s)" }
# export RPROMPT="%T"

cdpath=(~ ~/development)

# Use vi as the default editor
export EDITOR=vi

# But still use emacs-style zsh bindings (see https://superuser.com/a/457401)
bindkey -e

alias sif="$dotfilesDir/search-in-files.sh"
alias hgrep="$dotfilesDir/hgrep.sh"
alias update-my-config='curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/install.sh|bash'
alias update-my-config-skip-vsc='curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/install.sh | bash -s -- --skip-vsc'

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
alias d='docker'
alias dc='docker-compose'
alias dce='docker-compose exec'
alias dcl='docker-compose logs -f'
alias ccp='xclip -selection clipboard'
alias v='vi .'

autoload -Uz vcs_info
setopt prompt_subst

precmd() {
    vcs_info
    if [[ -n ${vcs_info_msg_0_} ]]; then
        upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2> /dev/null)

        if [[ -z $upstream ]] then
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

        # vcs_info found something (the documentation got that backwards
        # STATUS line taken from https://github.com/robbyrussell/oh-my-zsh/blob/master/lib/git.zsh
        STATUS=$(command git status --porcelain 2> /dev/null | tail -n1)
        if [[ -n $STATUS ]]; then
            RPROMPT='%{$fg_bold[red]%}${vcs_info_msg_0_} %{$fg_bold[cyan]%}$upstream_prompt%{$reset_color%}'
        else
            RPROMPT='%{$fg_bold[green]%}${vcs_info_msg_0_} %{$fg_bold[cyan]%}$upstream_prompt%{$reset_color%}'
        fi
    else
        # nothing from vcs_info

        # sample for github infos
        # token=$(cat .gh-token)
        # response=$(curl -s "https://api.github.com/search/issues?q=repo:user/repo+type:issue+state:open&access_token=$token" 2>/dev/null)
        # issueCount=$(echo $response | sed -En "s/^.*\"total_count\": ([0-9]+),.*$/\1/p")
        # response=$(curl -s "https://api.github.com/search/issues?q=repo:user/repo+type:pr+state:open&access_token=$token" 2>/dev/null)
        # prCount=$(echo $response | sed -En "s/^.*\"total_count\": ([0-9]+),.*$/\1/p")

        if isOS darwin
        then
            battery=$(pmset -g batt | egrep "([0-9]+)\%.*" -o --colour=auto | cut -f1 -d'%')
        else
            battery=$(cat /sys/class/power_supply/BAT0/uevent | sed -En "s/^.*POWER_SUPPLY_CAPACITY=([0-9]+).*$/\1/p")
        fi

        batteryColor=""
        if [[ $battery -lt 16 ]]
        then
            batteryColor="%{$fg_bold[red]%}"
        fi
        RPROMPT='%T | $batteryColor$battery%%%{$reset_color%}'
    fi
}

NEWLINE=$'\n'
PROMPT="%n@%m:%{$fg[yellow]%}%~%{$reset_color%}${NEWLINE}\$ "
zstyle ':vcs_info:git:*' formats "%b"
zstyle ':vcs_info:git:*' actionformats "%b %{$reset_color%}%{$fg_bold[blue]%}(%a)%{$reset_color%}"
zstyle ':vcs_info:*' enable git

source $dotfilesDir/yarn-completion.plugin.zsh
fpath=(~/.zsh/completion $fpath)
