#!/usr/bin/env zsh

dotfilesDir="$HOME/.dotfiles"

isOS()
{
    if [[ "$OSTYPE:l" == *"$1:l"* ]]
    then
        return 0;
    fi

    return 1;
}

isProgramInstalled()
{
    command -v $1 >/dev/null 2>&1 || { return 1 >&2; }
    return 0
}

source $dotfilesDir/alias.sh

autoload -Uz colors compinit promptinit
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

cdpath=(~ ~/development)

# Use vi as the default editor
export EDITOR=vi

# But still use emacs-style zsh bindings (see https://superuser.com/a/457401)
# Actually, no, use vi mode of course!
bindkey -v

bindkey -M viins 'jj' vi-cmd-mode

autoload -Uz vcs_info
setopt prompt_subst

nl=$'\n'

preexec() {
  if isOS darwin
  then
    timer=$(($(print -P %D{%s%6.})/1000))
  else
    timer=$(($(date +%s%0N)/1000000))
  fi
}

precmd() {
  if [ $timer ]; then
    if isOS darwin
    then
      now=$(($(print -P %D{%s%6.})/1000))
    else
      now=$(($(date +%s%0N)/1000000))
    fi

    elapsed=$(($now-$timer))
    elapsedHours=$(printf %02d $(($elapsed / 3600000)))
    elapsedMinutes=$(printf %02d $((($elapsed % 3600000) / 60000)))
    elapsedSeconds=$(printf %02d $((($elapsed % 60000) / 1000)))
    elapsedMilliseconds=$(printf %03d $(($elapsed % 1000)))
    elapsedTime="[${elapsedHours}:${elapsedMinutes}:${elapsedSeconds}.${elapsedMilliseconds}]$nl"
    #elapsedTime=" ${elapsedHours}:${elapsedMinutes}:${elapsedSeconds}.${elapsedMilliseconds} "
    unset timer
  fi

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

    RPROMPT='%T'
  fi
}


PROMPT='%{$reset_color%}$elapsedTime%{$reset_color%}%n@%m:%{$fg[yellow]%}%(5~|%-1~/…/%3~|%4~)%{$reset_color%}${nl}\$ '
zstyle ':vcs_info:git:*' formats "%b"
zstyle ':vcs_info:git:*' actionformats "%b %{$reset_color%}%{$fg_bold[blue]%}(%a)%{$reset_color%}"
zstyle ':vcs_info:*' enable git

# Necessary for added completions in .zsh/completion
fpath=($HOME/.zsh/completion $fpath)
autoload -Uz compinit && compinit -i


return 0

topbar ()
{
    local default="$(tput setab 172)$(tput setaf 0)"
    local reset="$(tput sgr0)"
    local branch="$(git rev-parse --abbrev-ref HEAD 2> /dev/null)"
    local nl=$'\n'
    local width=$(tput cols)
    local minWidth=30

    local start=" "
    local left=" left "
    local right=" $branch "
    local end=" "
    local fill="$(printf "%${$(($width - ${#start} - ${#left} - ${#right} - ${#end} - 4))}s")"

    local result="$default$start$reset "
    result+="$default$left$reset "
    result+="$default$fill$reset "
    result+="$default$right$reset "
    result+="$default$end"

  # Save cursor position
  tput sc
  # Move cursor to 0,0
  tput cup 0 0
  # Change scroll region to exclude the first line
  tput csr 1 $(($(tput lines) - 2))
  if [ $width -lt $minWidth ]
  then
      echo -ne "$default$(printf "%${width}s")$reset"
  else
      echo -ne "$result"
  fi
  # Restore cursor position
  tput rc
}

grey=%K{238}%F{7}
default=%F{172}
fg=%k%F{172}
light=%K{179}%F{0}
lighter=%K{222}%F{0}
lcarsAccentBg=%F{32}
lcarsAccentFg=%F{15}
reset=%f%k

prefix=$(echo -e '\u27a4')
bar='${$(topbar)//\%/%%}'
PROMPT="$bar$nl$grey\$elapsedTime$reset$nl$default%n@%m:%(5~|%-1~/…/%3~|%4~)$nl$prefix $reset"

