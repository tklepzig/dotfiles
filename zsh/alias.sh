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

if isProgramInstalled exa
then
    alias ls='exa'
    alias la='exa -a'
    alias ll='exa -l'
    alias lla='exa -la'
fi

alias rmr='rm -rf'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias t='tmux new-session -n ""'
alias ta='tmux a'

alias dotfiles-update='curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/install.sh | bash -s'
alias dotfiles-tabula-rasa="$dotfilesDir/tabula-rasa.sh"
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
alias gsa="$dotfilesDir/git/git-status-all.sh"
alias c='clear'
alias d='docker'
alias dc='docker-compose'
alias dce='docker-compose exec'
alias dcl='docker-compose logs -f'
alias dp='docker system prune -f && docker rmi -f $(docker images -q)'
alias ccp='xclip -selection clipboard'
alias v='vim'
alias vs='vim -S'

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
alias niwt="f(){ npm i \$1 && npm i -D @types/\$1; unset -f f }; f"

if isProgramInstalled pacman
then
    alias pmi='pacman -S'
    alias pmu='pacman -R'
fi

# Passing aliases when using sudo
alias sudo='sudo '

# TODO
# add auto-increment number as prefix to every file (remove -n to apply changes)
#rename -n 's/(.+)/our $i; sprintf("%02d-$1", 1+$i++)/e' *
