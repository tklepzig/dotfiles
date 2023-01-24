#!/usr/bin/env ruby
# frozen_string_literal: true

# neeeded for $CHILD_STATUS
require 'English'
require_relative './utils'

HOME ||= ENV['HOME']
DF_PROFILES ||= ENV['DOTFILES_PROFILES']
DF_THEME ||= ENV['DOTFILES_THEME']
DF_PATH ||= "#{HOME}/.dotfiles"

# https://rubystyle.guide/
# TODO: symlink my own global config to $HOME/.rubocop.yml

def merge(base_path, override_path)
  base = File.readlines(base_path)
  override = File.readlines(override_path)

  result = base.reject { |line| override.include?("-#{line}") }
  result += override.reject { |line| line.start_with?('-') }
  File.write(base_path, result.join)
end

def link_vim_plugins(profile)
  if File.exist?("#{DF_PATH}/vim/#{profile}/plugins.vim.override")
    merge("#{DF_PATH}/vim/#{profile}/plugins.vim",
          "#{DF_PATH}/vim/#{profile}/plugins.vim.override")
  end

  `sed 's/\\"pluginfile/source $HOME\\/.dotfiles\\/vim\\/#{profile}\\/plugins.vim\\
\\"pluginfile/g' $HOME/.plugins.vim > $HOME/.plugins.vim.tmp && mv $HOME/.plugins.vim.tmp $HOME/.plugins.vim`
end

def install_profiles
  (['basic'] + DF_PROFILES.split(' ')).each do |profile|
    Logger.log 'Installing Profile ', profile.accent, '...'
    Logger.indent

    link_vim_plugins profile
    add_link_to_file "#{DF_PATH}/vim/#{profile}/vimrc", "#{HOME}/.vimrc"

    # setup_file = "#{DF_PATH}/vim/#{profile}/install.rb"
    # require_relative setup_file if File.exist?(setup_file)
    setup_file = "#{DF_PATH}/vim/#{profile}/install.sh"
    `source "#{setup_file}"` if File.exist?(setup_file)

    add_link_to_file "#{DF_PATH}/zsh/#{profile}/zshrc.zsh", "#{HOME}/.zshrc"

    Logger.reset_indentation
    Logger.log 'Done.'.success
  end
end

check_mandatory_installation 'zsh'

`source "#{DF_PATH}/setTheme.zsh"`
add_link_to_file "#{DF_PATH}/colours.vim", "#{HOME}/.vimrc"
add_link_to_file "#{DF_PATH}/colours.vim", "#{HOME}/.zshrc"
add_link_to_file "#{DF_PATH}/colours.vim", "#{HOME}/.tmux.conf"

if File.exist?("#{HOME}/.plugins.custom.vim")
  File.write("#{HOME}/.plugins.custom.vim",
             "\"Plug 'any/vim-plugin'")
end

`cp #{DF_PATH}/vim/plugins.vim #{HOME}/.plugins.vim`
add_link_to_file "#{DF_PATH}/vim/plugins.vim", "#{HOME}/.vimrc"

install_profiles

unless Dir.exist?("#{HOME}/.vim/autoload/plug.vim")
  Logger.log 'Installing vim-plug...'
  `curl -fLo #{HOME}/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim>/dev/null 2>&1`
  Logger.log 'Done.'.success
end

Logger.log ' "Installing and updating vim plugins..."'
# "echo" to suppress the "Please press ENTER to continue...
`echo | vim +PlugInstall +PlugUpdate +qall > /dev/null 2>&1`
Logger.log 'Done.'.success

if DF_PROFILES.include?('dev')
  # The dev profile is activated and so the coc plugin is installed
  Logger.log 'Updating coc extensions...'
  `echo | vim +CocUpdate +qall > /dev/null 2>&1`
  Logger.log 'Done.'.success
end

# TODO
# Ensure the following line is in .zshrc after all df includes
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

Logger.log 'Setting up zsh sounds...'
`mkdir -p #{HOME}/.zsh-sounds`
`cp #{DF_PATH}/zsh/sounds-readme.md #{HOME}/.zsh-sounds/README.md`
Logger.log 'Done.'.success

if OS.mac?
  add_link_to_file "#{DF_PATH}/tmux/vars.osx.conf", "#{HOME}/.tmux.conf"
else
  add_link_to_file "#{DF_PATH}/tmux/vars.linux.conf", "#{HOME}/.tmux.conf"
end
add_link_to_file "#{DF_PATH}/tmux/tmux.conf", "#{HOME}/.tmux.conf"

if program_installed? kitty
  add_link_to_file "#{DF_PATH}/kitty/kitty.conf", "#{HOME}/.config/kitty/kitty.conf", 'include'

  if DF_THEME == 'lcars-light'
    add_link_to_file "#{DF_PATH}/kitty/kitty.lcars-light.conf", "#{HOME}/.config/kitty/kitty.conf", 'include'
  end
end

check_optional_installation 'exa'
check_optional_installation 'tmux'
check_optional_installation 'lynx'

Logger.log 'Configuring Git...'
`#{DF_PATH}/git/git-config.sh`
Logger.log 'Done.'.success

# docker stuff
# set default shell to zsh if necessary
