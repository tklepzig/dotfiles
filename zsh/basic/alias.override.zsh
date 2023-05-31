alias a="say -v 'Anna'"
alias aws='function __aws() {  aws-session thomas.mueller "$1"; source ~/.zshrc; }; __aws'

alias bers="ENV=test RAILS_ENV=test RACK_ENV=test ber spec"
alias brewbundle="cd $HOME && brew bundle && cd -"
alias brewfile="vim ~/source/dotfiles/Brewfile"
alias brewup="brew update && brew upgrade && brew cleanup"

alias dcb="dc build"
alias dcbt="dcb && dc run app test"
alias dcs="dc stop"
alias dct="dc run app test"

alias gco='git checkout'
alias gfm='git pull'
alias gunwip='git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign -m "--wip-- [skip ci]"'

alias ll='exa -lga'
alias localip='ifconfig | grep -Eo '\''inet (addr:)?([0-9]*\.){3}[0-9]*'\'' | grep -Eo '\''([0-9]*\.){3}[0-9]*'\'' | grep -v '\''127.0.0.1'\'
alias ls='exa -lg'

alias maik="netstat -anv | grep LISTEN"
alias maikpostgres="maik | grep 5432"
alias maikrabbitmq="maik | grep 5672"
alias maikredis="maik | grep 6379"

alias n="nvim"
alias nrf='npm run format'
alias nrt="npm run test"
alias nvimup="asdf install neovim latest && asdf global neovim latest"

alias prepare='asdf install && b && ni'

alias readme="vim ./README.md"

alias src="cd ~/source/"
alias s="source ~/.zshrc"

alias tmuxconf="vim ~/.tmux.conf"

alias update="vimup && nvimup && brewup && brewbundle"

alias vimdel="find . -type f -name '*.sw[klmnop]' -delete"
alias vimrc="vim ~/.vimrc"
alias vimup="asdf install vim latest && asdf global vim latest"

alias y="say -v 'Yuri'"
alias yolo='rm -rf node_modules/ && ni'

alias zshrc="vim ~/.zshrc"
