dotfilesRepo=${DOTFILES_REPO:-"tklepzig/dotfiles"}

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

if isProgramInstalled eza
then
    alias ls='eza'
    alias la='eza -a'
    alias ll='eza -l'
    alias lla='eza -la'
fi

alias rmr='rm -rf'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias t='tmux new-session -n ""'
alias ta='tmux a'

alias dotfiles-update='/usr/bin/env ruby -e "$(curl -Ls https://raw.githubusercontent.com/$dotfilesRepo/master/setup.rb)"'
alias dfu='dotfiles-update'
alias dotfiles-update-legacy='/usr/bin/env zsh -c "$(curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/install.sh)"'
alias dotfiles-tabula-rasa="$dotfilesDir/tabula-rasa.sh"

alias notify="$dotfilesDir/notify.rb"
alias battery-monitor="$dotfilesDir/battery-monitor.rb"
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
alias c='clear'
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcup='docker compose up --pull always -d'
alias dcd='docker compose down --remove-orphans'
alias dcdv='docker compose down --remove-orphans --volumes'
alias dce='docker compose exec'
alias dcl='docker compose logs -f'
alias dp='docker system prune -f && docker rmi -f $(docker images -q)'
alias ccp='xclip -selection clipboard'

if [ -n "$DOTFILES_NVIM" ]
then
    alias vim='test -n "$VIMRUNTIME" && exit || nvim'
else
    alias vim='test -n "$VIMRUNTIME" && exit || vim'
fi

alias v='vim'
alias vs='vim -S'

# Open all files of current branch
alias vbf="vim \$(g bf)"

# Open all files which are currently changed or created (git diff)
alias vdf="f(){ git a; files=\$(git ds --name-only); git r; vim \$(echo \"\$files\"); unset -f f }; f"

# Open all files of a specific commit $1
alias vcf="f(){ vim \$(git show --pretty='format:' --name-only \"\$1\"); unset -f f }; f"

# With `. ranger` (or `source ranger`) the last visited directory will be used for the shell when exiting ranger
# If you want to go back where you left off, just enter `cd -`
# See also https://unix.stackexchange.com/a/570812 and https://github.com/ranger/ranger/blob/master/ranger.py
alias r='. ranger'

alias q='exit'
alias ..='cd ..'
alias ly="lynx -cfg $dotfilesDir/lynx.cfg"
alias ni='npm install'
alias nu='npm uninstall'
alias nid='npm install -D'
alias nr='npm run'
alias nrt='npm run test 2>&1 | grep ●'
alias niwt="f(){ npm i \$1 && npm i -D @types/\$1; unset -f f }; f"
alias nmc="find . -name 'node_modules' -type d -prune -exec rm -rf '{}' +"

alias ai="asdf install"

if isProgramInstalled pacman
then
    alias pm='sudo pacman'
fi

# Passing aliases when using sudo
alias sudo='sudo '

# TODO
# add auto-increment number as prefix to every file (remove -n to apply changes)
#rename -n 's/(.+)/our $i; sprintf("%02d-$1", 1+$i++)/e' *

# Delete recursively all node_modules folders
#find . -name 'node_modules' -type d -prune -exec rm -rf '{}' +
