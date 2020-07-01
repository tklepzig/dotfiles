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
alias t='tmux'

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
alias c='code-insiders .'
alias d='docker'
alias dc='docker-compose'
alias dce='docker-compose exec'
alias dcl='docker-compose logs -f'
alias dp='docker system prune -f && docker rmi -f $(docker images -q)'
alias ccp='xclip -selection clipboard'
alias v='vi .'
alias r='ranger'
alias q='exit'
alias ..='cd ..'
alias ly="lynx -cfg $dotfilesDir/lynx.cfg"
alias niwt="f(){ npm i \$1 && npm i -D @types/\$1; unset -f f }; f"
