#!/usr/bin/env zsh

/usr/bin/env zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

brew install git
brew install --cask kitty google-chrome

brew install wget wemux websocat btop lynx ddgr exa pqiv ranger the_silver_searcher tig tmux bat pam-reattach
brew install --cask gimp insomnia licecap raycast vnc-viewer ultimaker-cura seafile-client audacity vlc iterm2

brew install awscli
brew install --cask docker browserstacklocal slack discord tunnelblick gpg-suite visual-studio-code

git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
$HOME/.fzf/install
