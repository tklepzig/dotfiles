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
accent=%F{32}
warning=%F{196}
accentTile=%K{32}%F{15}
defaultTile=%K{172}%F{0}
greyTile=%K{238}%F{7}
warningTile=%K{124}%F{255}
reset=%f%k%b

source $dotfilesDir/zsh/alias.sh

# Add completions from .zsh/completion
fpath=($HOME/.zsh/completion $fpath)

if [ -d "$HOME/.asdf" ]
then
  source $HOME/.asdf/asdf.sh
  fpath=(${ASDF_DIR}/completions $fpath)
fi

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
setopt nonomatch
setopt prompt_subst
setopt correct

unsetopt auto_cd

cdpath=(~ ~/development)

# Use vi as the default editor
export EDITOR=vim
export VISUAL=vim

export SPROMPT="$warningTile $reset Correct $warning%R$reset to $default%r$reset? (nyae)$reset"
 
# Use vi-style zsh bindings
bindkey -v

bindkey -M viins 'jj' vi-cmd-mode
bindkey -M vicmd v edit-command-line


# search history with current entered text via up/down (starts-with search)
# If it does not work on the current OS, try to find out the correct code with `cat -v` or `Ctrl+V`
# and set ZSH_HISTORY_KEY_UP and ZSH_HISTORY_KEY_DOWN accordingly BEFORE sourcing this script
if [ ! $ZSH_HISTORY_KEY_UP ]
then
  ZSH_HISTORY_KEY_UP='^[[A'
fi
autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search
bindkey "$ZSH_HISTORY_KEY_UP" up-line-or-beginning-search

if [ ! $ZSH_HISTORY_KEY_DOWN ]
then
  ZSH_HISTORY_KEY_DOWN='^[[B'
fi
autoload -U down-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "$ZSH_HISTORY_KEY_DOWN" down-line-or-beginning-search


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

    if [ "$lastExitCode" != 0 ]
    then
      lastExitCodeString=" $warningTile $lastExitCode "
    fi

    unset timer

    playSound
  fi

  vcs_info

  local repoStatus=$(command git status --porcelain 2> /dev/null | tail -n1)
  local branchColor="$([[ -n $repoStatus ]] && echo "$accentTile $reset$accent%B " || echo "$defaultTile $reset$default%B ")"
  local repoInfoOrUser="$default%n@%m$reset$nl"

  if [[ -n ${vcs_info_msg_0_} ]]
  then
    repoInfoOrUser="$branchColor${vcs_info_msg_0_}$(upstreamIndicator)$reset$nl"
  fi

  local prefix=$(echo -e '\u276f')
  #local prefix=$(echo -e '\u261e')
  local path="%(5~|%-1~/…/%3~|%4~)"
  PROMPT="$greyTile\$elapsedTime$reset\$lastExitCodeString$reset$nl$nl$repoInfoOrUser$light$path$nl$default$prefix $reset"
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
  # exit code 130 means the user pressed CTRL+C (128 + SIGINT -> 128 + 2)
  # exit code 146/148 means the user pressed CTRL+Z (128 + SIGTSTP -> 128 + 20 (linux) or 18 (osx))
  if [ "$lastExitCode" != 0 ] && [ "$lastExitCode" != 130 ] && [ "$lastExitCode" != 146 ] && [ "$lastExitCode" != 148 ] && [ -f "$soundsPath/command-failed.mp3" ]
  then
    (&>/dev/null afplay -v 0.1 "$soundsPath/command-failed.mp3" &)
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

ZSH_SOUND=0
