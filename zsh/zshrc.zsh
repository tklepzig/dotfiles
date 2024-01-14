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
primary=%F{$primaryText}
secondary=%F{$secondaryText}
accent=%F{$accentText}
warning=%F{$criticalBg}
primaryTile=%K{$primaryBg}%F{$primaryFg}
accentTile=%K{$accentBg}%F{$accentFg}
greyTile=%K{$infoBg}%F{$infoFg}
warningTile=%K{$criticalBg}%F{$criticalFg}
reset=%f%k%b

source $dotfilesDir/zsh/alias.zsh

# Add completions from .zsh/completion
fpath=($HOME/.zsh/completion $fpath)

autoload -Uz colors compinit promptinit edit-command-line vcs_info
colors
promptinit
compinit
zle -N edit-command-line

zstyle ':completion:*' menu select
zstyle ':vcs_info:git:*' formats "%b"
zstyle ':vcs_info:git:*' actionformats "%b (%a)"
zstyle ':vcs_info:*' enable git

#TODO
#
#zstyle ':completion:*' list-colors ${(s.:.)"di=32:ln=35:so=33:pi=33:ex=31:bd=1;34:cd=1;34:su=1;31:sg=1;31:tw=1;32:ow=1;32"}
#
#how to color completion via rule instead of using escape codes (see _run.rb)
#zstyle ':completion:*:default' list-colors '=(#b)*(XX *)=32=31' '=*=32'
#zstyle ":completion:*:default" list-colors ${(s.:.)LS_COLORS} "ma=48;5;153;1"
#https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#Colored-completion-listings
#https://www.ditig.com/256-colors-cheat-sheet
#https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
#https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
#https://www.zsh.org/mla/users/2017/msg00334.html
#https://superuser.com/questions/1200487/zsh-completion-list-colors-partial-colouring-issue
#https://thevaluable.dev/zsh-completion-guide-examples/
#https://github.com/ohmyzsh/ohmyzsh/issues/9728
#https://github.com/zsh-users/zsh-completions/blob/master/zsh-completions-howto.org

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
# Use vim as the default editor
export EDITOR=vim
export VISUAL=vim

export SPROMPT="$warningTile $reset Correct $warning%R$reset to $primary%r$reset? (nyae)$reset"

# Use vi-style zsh bindings
bindkey -v

bindkey -M viins 'jj' vi-cmd-mode
bindkey -M vicmd v edit-command-line


# Make HOME, END and DEL working (is sometimes necessary?!)
bindkey '\e[H'  beginning-of-line
bindkey '\e[F'  end-of-line
bindkey '\e[3~' delete-char
# inside tmux the keycodes differ for whatever reason...
bindkey '\e[1~'  beginning-of-line
bindkey '\e[4~'  end-of-line

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

export ASDF_RUBY_BUILD_VERSION=master
# Don't do that, some gems don't care about frozen and will crash with this set as default
#export RUBYOPT=--enable-frozen-string-literal

# In case instaling ruby via asdf fails due to missing header files, try the following
#export RUBY_CONFIGURE_OPTS="--with-zlib-dir=$(brew --prefix zlib) --with-openssl-dir=$(brew --prefix openssl@3) --with-readline-dir=$(brew --prefix readline) --with-libyaml-dir=$(brew --prefix libyaml)"

# Put the name of the default branch into $DOTFILES_GIT_DEFAULT_BRANCH (either master or main)
chpwd() {
  gitRoot=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ $? = 0 ]
  then
    export DOTFILES_GIT_DEFAULT_BRANCH=$([ -f "$gitRoot/.git/refs/heads/master" ] && echo master || echo main)
  fi
}

function zle-line-init zle-keymap-select {
    case $KEYMAP in
        (vicmd) viCmdIndicator="$accentTile NORMAL $reset$nl" ;;
        (*)     viCmdIndicator="" ;;
    esac
    zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select

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
    else
      lastExitCodeString=""
    fi

    unset timer
  fi

  vcs_info

  local repoStatus=$(command git status --porcelain 2> /dev/null | tail -n1)
  local branchColor="$([[ -n $repoStatus ]] && echo "$accentTile $reset$accent%B " || echo "$primaryTile $reset$primary%B ")"
  local repoInfoOrUser="$primary%n@%m$reset$nl"

  if [[ -n ${vcs_info_msg_0_} ]]
  then
    repoInfoOrUser="$branchColor${vcs_info_msg_0_}$(upstreamIndicator)$reset$nl"
  fi

  if [ "$EUID" != 0 ]
  then
    local prefix=$(echo -e '\u276f')
  else
    # special prompt prefix for root
    local prefix="$warning#"
  fi
  #local prefix=$(echo -e '\u261e')
  local path="%(5~|%-1~/…/%3~|%4~)"

  if [ -n "$VIMRUNTIME" ]
  then
    local inVimOrPrefix="${accentTile}vim $prefix$reset "
  else
    local inVimOrPrefix="$primary$prefix$reset "
  fi

  PROMPT="$greyTile\$elapsedTime$reset\$lastExitCodeString$reset$nl$nl$repoInfoOrUser$secondary$path$nl\$viCmdIndicator$inVimOrPrefix"
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

if isOS linux
then
  # Map caps lock to escape; To reset it, run: setxkbmap -option ''
  setxkbmap -option caps:escape
fi
