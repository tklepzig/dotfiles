#!/usr/bin/env ruby

# neeeded for $CHILD_STATUS
require 'English'
require_relative './utils'

DOTFILES_PATH ||= "#{ENV['HOME']}/.dotfiles"

# https://rubystyle.guide/
# TODO: symlink my own global config to $HOME/.rubocop.yml

def link_vim_plugins(profile)
  `sed 's/\\"pluginfile/source $HOME\\/.dotfiles\\/vim\\/#{profile}\\/plugins.vim\\
\\"pluginfile/g' $HOME/.plugins.vim > $HOME/.plugins.vim.tmp && mv $HOME/.plugins.vim.tmp $HOME/.plugins.vim`
end

def install_profiles
  (['basic'] + ENV['DOTFILES_PROFILES'].split(' ')).each do |profile|
    Logger.log 'Installing Profile ', profile.accent, '...'
    Logger.indent

    link_vim_plugins profile
    add_link_to_file "#{DOTFILES_PATH}/vim/#{profile}/vimrc", "#{ENV['HOME']}/.vimrc2"

    setup_file = "#{DOTFILES_PATH}/vim/#{profile}/install.rb"
    # `source "#{setup_file}"` if File.exist?(setup_file)
    require_relative setup_file if File.exist?(setup_file)

    add_link_to_file "#{DOTFILES_PATH}/zsh/#{profile}/zshrc.zsh", "#{ENV['HOME']}/.zshrc2"

    Logger.reset_indentation
    Logger.log 'Done.'.success
  end
end

check_mandatory_installation 'zsh'

# set theme
# create custom plugin file
# backup existing vim plugin file
# copy plugin file to home, link it to .vimrc
# install profiles
# Install vim-plug
# PlugInstall and PlugUpdate
# Ensure the fzf thingy
# zsh sounds
# link tmux files
# link kitty files
# check programs
# configure git
# docker stuff
# set default shell to zsh if necessary
