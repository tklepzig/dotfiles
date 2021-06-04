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

nl=$'\n'
default=%F{172}
light=%F{179}
lighter=%F{222}
#accent=%F{32} too dark on black bg
accent=%F{4}
accentTile=%K{32}%F{15}
defaultTile=%K{172}%F{0}
greyTile=%K{238}%F{7}
reset=%f%k

source $dotfilesDir/zsh/alias.sh
source $HOME/.asdf/asdf.sh

# Add completions from .zsh/completion
fpath=($HOME/.zsh/completion $fpath)

# Add asdf completions
fpath=(${ASDF_DIR}/completions $fpath)

autoload -Uz colors compinit promptinit edit-command-line vcs_info
colors
promptinit
compinit
zle -N edit-command-line

zstyle ':completion:*' menu select
zstyle ':vcs_info:git:*' formats "%b"
zstyle ':vcs_info:git:*' actionformats "%b (%a)"
zstyle ':vcs_info:*' enable git

HISTFILE=$HOME/.history
HISTSIZE=10000
SAVEHIST=20000
setopt hist_ignore_all_dups
setopt inc_append_history
setopt auto_cd
setopt nonomatch
setopt prompt_subst

cdpath=(~ ~/development)

# Use vi as the default editor
export EDITOR=vim
export VISUAL=vim

# Use vi-style zsh bindings
bindkey -v

bindkey -M viins 'jj' vi-cmd-mode
bindkey -M vicmd v edit-command-line

preexec() {
  if isOS darwin
  then
    timer=$(($(print -P %D{%s%6.})/1000))
  else
    timer=$(($(date +%s%0N)/1000000))
  fi
}

precmd() {
  lastExitCode=$?

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
    elapsedTime=" ${elapsedHours}:${elapsedMinutes}:${elapsedSeconds}.${elapsedMilliseconds} "
    unset timer

    playSound
  fi

  vcs_info

  local repoStatus=$(command git status --porcelain 2> /dev/null | tail -n1)
  local branchColor="$([[ -n $repoStatus ]] && echo "$accentTile $reset$accent " || echo "$defaultTile $reset$default ")"
  local repoInfoOrUser="$default%n@%m$reset$nl"

  if [[ -n ${vcs_info_msg_0_} ]]
  then
    repoInfoOrUser="$branchColor${vcs_info_msg_0_}$(upstreamIndicator)$reset$nl"
  fi

  local prefix=$(echo -e '\u276f')
  local bar='${$(topbar)//\%/%%}'
  local path="%(5~|%-1~/…/%3~|%4~)"
  PROMPT="$bar$greyTile\$elapsedTime$reset$nl$nl$repoInfoOrUser$light$path$nl$default$prefix $reset"
}

playSound()
{
  if [[ $ZSH_SOUND = 0 ]]
  then
    return 0
  fi

  player=""
  if isOS darwin
  then
    player="afplay"
  fi

  if ! isProgramInstalled $player
  then
    return 0
  fi

  soundsPath="$HOME/.zsh-sounds"
  if [ "$lastExitCode" != 0 ] && [ -f "$soundsPath/command-failed.mp3" ]
  then
    (&>/dev/null afplay -v 0.2 "$soundsPath/command-failed.mp3" &)
  elif [ $elapsed -gt 60000 ] && [ -f "$soundsPath/long-running-command-success.mp3" ]
  then
    (&>/dev/null afplay -v 0.2 "$soundsPath/long-running-command-success.mp3" &)
  fi
}

upstreamIndicator() 
{
  if [[ -z "$(git rev-parse --abbrev-ref HEAD 2> /dev/null)" ]]
  then
    echo ""
    return
  fi

  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2> /dev/null)

  if [[ -z $upstream ]] then
    echo " #";
  else
    upstream_info=$(git rev-list --left-right --count $upstream...HEAD 2> /dev/null)
    case "$upstream_info" in
      "") # no upstream
        echo "" ;;
      "0	0") # equal to upstream
        echo " =" ;;
      "0	"*) # ahead of upstream
        echo " >" ;;
      *"	0") # behind upstream
        echo " <" ;;
      *)	    # diverged from upstream
        echo " <>" ;;
    esac
  fi
}

topbar_show ()
{
  ZSH_TOP_BAR=""
}

topbar_hide ()
{
  ZSH_TOP_BAR="hidden"
  tput sc
  tput cup 0 0
  tput el
  tput csr 0 $(($(tput lines)))
  tput rc
}

set_topbar_title ()
{
  ZSH_TOP_BAR_TITLE="$1"
}

alias tbh='topbar_hide' 
alias tbs='topbar_show' 
alias tbt='set_topbar_title'

topbar ()
{
  if [[ "$ZSH_TOP_BAR" = "hidden" ]]
  then
    return 0
  fi

  local default="$(tput setab 172)$(tput setaf 0)"
  local fg="$(tput setaf 172)"
  local accent="$(tput setab 32)$(tput setaf 15)"
  local light="$(tput setab 179)$(tput setaf 0)"
  local lighter="$(tput setab 222)$(tput setaf 0)"
  local reset="$(tput sgr0)"
  local nl=$'\n'
  local width=$(tput cols)


  local title=$ZSH_TOP_BAR_TITLE
  if [[ -n $title ]]
  then
    local start="   "
    local end=" "
    local fullMinWidth=$((${#start} + ${#title} + ${#end} + 2))
    local lightMinWidth=$fullMinWidth
    local fill="$(printf "%${$(($width - ${#start} - ${#title} - ${#end} - 2))}s")"
    full="$default$start$fill$reset$fg $title $default$end"
    light=$full
  else
    local start=" "
    local end=" "
    local user=" $(whoami) "
    local host=" $(hostname -s) "
    local repoStatus=$(command git status --porcelain 2> /dev/null | tail -n1)
    local branch=" $(git rev-parse --abbrev-ref HEAD 2> /dev/null)$(upstreamIndicator) "
    local branchColor="$([[ -n $repoStatus ]] && echo $accent || echo $default)"

    local fullMinWidth=$((${#start} + ${#user} + ${#host} + ${#branch} + ${#end} + 6))
    local lightMinWidth=$((${#start} + ${#branch} + ${#end} + 4))
    local fillFull="$(printf "%${$(($width - ${#start} - ${#user} - ${#host} - ${#branch} - ${#end} - 5))}s")"
    local fillLight="$(printf "%${$(($width - ${#start} - ${#branch} - ${#end} - 3))}s")"

    local full="$default$start$reset "
    full+="$light$user$reset "
    full+="$light$host$reset "
    full+="$default$fillFull$reset "
    full+="$branchColor$branch$reset "
    full+="$default$end"

    local light="$default$start$reset "
    light+="$default$fillLight$reset "
    light+="$branchColor$branch$reset "
    light+="$default$end"
  fi

  local mini="$default$(printf "%${width}s")$reset"

  # Save cursor position
  tput sc
  # Move cursor to 0,0
  tput cup 0 0
  # Change scroll region to exclude the first line
  tput csr 1 $(($(tput lines) - 1))
  if [ $width -lt $fullMinWidth ]
  then
    if [ $width -lt $lightMinWidth ]
    then
      echo -ne "$mini"
    else
      echo -ne "$light"
    fi
  else
    echo -ne "$full"
  fi

  # Restore cursor position
  tput rc
}


ZSH_SOUND=0
ZSH_TOP_BAR="hidden"
