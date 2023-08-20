#!/usr/bin/env ruby
# frozen_string_literal: true

# neeeded for $CHILD_STATUS and $PROGRAM_NAME
require 'English'

DF_REPO ||= ENV['DOTFILES_REPO'] || 'tklepzig/dotfiles'
HOME ||= ENV['HOME']
DF_PROFILES ||= ENV['DOTFILES_PROFILES'] || ''
DF_THEME ||= ENV['DOTFILES_THEME']
DF_PATH ||= "#{HOME}/.dotfiles"

# https://rubystyle.guide/
# TODO: symlink my own global config to $HOME/.rubocop.yml

class String
  def accent
    colorize "\e[1;34m"
  end

  def success
    colorize "\e[0;92m"
  end

  def error
    colorize "\e[0;91m"
  end

  private

  def colorize(color)
    "#{color}#{self}\e[0m"
  end
end

module Logger
  @level = 0

  def self.log(*message_parts, newline: true)
    message = message_parts.join
    message = message.rjust(message.length + 2 * @level)

    if newline
      puts message
    else
      print message
    end
  end

  def self.indent
    @level += 1
  end

  def self.outdent
    @level -= 1
    @level = 0 if @level.negative?
  end

  def self.reset_indentation
    @level = 0
  end
end

module OS
  def self.mac?
    (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def self.linux?
    (/linux/ =~ RUBY_PLATFORM) != nil
  end
end

def find_override(file_path)
  return "#{file_path}.override" if File.exist?("#{file_path}.override")

  override_before_extension = file_path.gsub(/(.*)(\..+)$/, '\1.override\2')
  return override_before_extension if File.exist?(override_before_extension)
end

def merge(base_path, override_path)
  base = File.readlines(base_path)
  override = File.readlines(override_path)

  result = base.reject { |line| override.include?("-#{line}") }
  result += override.reject { |line| line.start_with?('-') }
  File.write(base_path, result.join)
end

def program_installed?(program)
  result = `sh -c 'command -v #{program}'`
  return true unless result.empty?

  false
end

def check_mandatory_installation(program)
  Logger.log 'Searching for ', program.accent, '...', newline: false

  unless program_installed? program
    Logger.log ' Not found, aborting'.error
    exit(false)
  end

  path = `which #{program}`
  Logger.log " Found: #{path.strip}.".success
end

def check_optional_installation(program, install_name = program)
  Logger.log 'Searching for ', program.accent, '...', newline: false

  if program_installed? program
    Logger.log ' Found.'.success
    return
  end

  Logger.log " Not Found. (Try \"sudo pacman -S #{install_name}\")".error
end

def write_link(link, file, command = 'source')
  `grep -q #{link} #{file}`
  return if $CHILD_STATUS.success?

  Logger.log 'Adding link to ', file.accent, '...', newline: false
  File.open(file, 'a') do |f|
    f.puts "#{command} #{link}"
  end
  Logger.log ' Done.'.success
end

def add_link_with_override(link, file, command = 'source')
  File.new(file, 'w') unless File.exist?(file)

  write_link(link, file, command)

  override = find_override(link)
  return unless override

  write_link(override, file, command)
end

def link_vim_plugins(profile)
  if File.exist?("#{DF_PATH}/vim/#{profile}/plugins.override.vim")
    merge("#{DF_PATH}/vim/#{profile}/plugins.vim",
          "#{DF_PATH}/vim/#{profile}/plugins.override.vim")
  end

  `sed 's/\\"pluginfile/source $HOME\\/.dotfiles\\/vim\\/#{profile}\\/plugins.vim\\
\\"pluginfile/g' #{HOME}/.plugins.vim > #{HOME}/.plugins.vim.tmp && mv #{HOME}/.plugins.vim.tmp #{HOME}/.plugins.vim`
end

def install_profiles
  (['basic'] + DF_PROFILES.split(' ')).each do |profile|
    Logger.log 'Installing Profile ', profile.accent, '...'
    Logger.indent

    link_vim_plugins profile
    add_link_with_override "#{DF_PATH}/vim/#{profile}/vimrc", "#{HOME}/.vimrc"

    setup_file = "#{DF_PATH}/vim/#{profile}/install.rb"
    require setup_file if File.exist?(setup_file)

    add_link_with_override "#{DF_PATH}/zsh/#{profile}/zshrc.zsh", "#{HOME}/.zshrc"

    Logger.reset_indentation
    Logger.log 'Done.'.success
  end
end

def install
  check_mandatory_installation 'git'
  check_mandatory_installation 'zsh'

  if Dir.exist?(DF_PATH)
    Logger.log "Found existing dotfiles in #{DF_PATH}, updating...", newline: false
    Dir.chdir(DF_PATH) do
      # Update repo
      `git fetch --depth=1 > /dev/null 2>&1`
      # Remove tracked changes
      `git reset --hard origin/master > /dev/null 2>&1`
      # Remove ignored changes
      `git clean -fx > /dev/null 2>&1`
    end
  else
    Logger.log "Cloning repo to #{DF_PATH}...", newline: false
    `git clone --depth=1 https://github.com/#{DF_REPO}.git #{DF_PATH} > /dev/null 2>&1`
  end
  Logger.log ' Done.'.success

  `#{DF_PATH}/setTheme.zsh`
  add_link_with_override "#{DF_PATH}/colours.vim", "#{HOME}/.vimrc"
  add_link_with_override "#{DF_PATH}/colours.zsh", "#{HOME}/.zshrc"
  add_link_with_override "#{DF_PATH}/colours.zsh", "#{HOME}/.tmux.conf"

  unless File.exist?("#{HOME}/.plugins.custom.vim")
    File.write("#{HOME}/.plugins.custom.vim",
               "\"Plug 'any/vim-plugin'")
  end

  `cp #{DF_PATH}/vim/plugins.vim #{HOME}/.plugins.vim`
  add_link_with_override "#{HOME}/.plugins.vim", "#{HOME}/.vimrc"

  Logger.log 'Initializing toolbox...'
  add_link_with_override "#{DF_PATH}/toolbox/init.zsh", "#{HOME}/.zshrc"
  Logger.log 'Done.'.success

  install_profiles

  unless Dir.exist?("#{HOME}/.vim/autoload/plug.vim")
    Logger.log 'Installing vim-plug...', newline: false
    `curl -fLo #{HOME}/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim>/dev/null 2>&1`
    Logger.log ' Done.'.success
  end

  Logger.log 'Installing and updating vim plugins...', newline: false
  # "echo" to suppress the "Please press ENTER to continue...
  `echo | vim +PlugInstall +PlugUpdate +qall > /dev/null 2>&1`
  Logger.log ' Done.'.success

  if DF_PROFILES.include?('dev')
    # The dev profile is activated and so the coc plugin is installed
    Logger.log 'Updating coc extensions...', newline: false
    `echo | vim +CocUpdate +qall > /dev/null 2>&1`
    Logger.log ' Done.'.success
  end

  if OS.mac?
    add_link_with_override "#{DF_PATH}/tmux/vars.osx.conf", "#{HOME}/.tmux.conf"
  else
    add_link_with_override "#{DF_PATH}/tmux/vars.linux.conf", "#{HOME}/.tmux.conf"
  end
  add_link_with_override "#{DF_PATH}/tmux/tmux.conf", "#{HOME}/.tmux.conf"

  if program_installed? 'kitty'
    add_link_with_override "#{DF_PATH}/kitty/kitty.conf", "#{HOME}/.config/kitty/kitty.conf", 'include'

    if DF_THEME == 'lcars-light'
      add_link_with_override "#{DF_PATH}/kitty/kitty.lcars-light.conf", "#{HOME}/.config/kitty/kitty.conf", 'include'
    end
  end

  unless Dir.exist?("#{HOME}/.fzf")
    Logger.log 'Installing fzf...', newline: false
    `git clone --depth 1 https://github.com/junegunn/fzf.git #{HOME}/.fzf > /dev/null 2>&1`
    `#{HOME}/.fzf/install --all > /dev/null 2>&1`
    Logger.log ' Done.'.success
  end

  check_optional_installation 'exa'
  check_optional_installation 'tmux'
  check_optional_installation 'lynx'

  Logger.log 'Configuring Git...', newline: false
  `#{DF_PATH}/git/git-config.sh`
  Logger.log ' Done.'.success

  if program_installed? 'docker'
    Logger.log 'Installing docker completion...', newline: false
    `mkdir -p #{HOME}/.zsh/completion`
    `curl -L https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker > #{HOME}/.zsh/completion/_docker 2>/dev/null`
    `curl -L https://raw.githubusercontent.com/docker/compose/master/contrib/completion/zsh/_docker-compose > #{HOME}/.zsh/completion/_docker-compose 2>/dev/null`
    Logger.log ' Done.'.success
  end

  default_shell = if OS.mac?
                    `dscl . -read #{HOME}/ UserShell | sed 's/UserShell: //'`
                  else
                    `grep ^$(id -un): /etc/passwd | cut -d : -f 7-`
                  end

  return unless default_shell != `which zsh`

  Logger.log 'Setting default shell to zsh...', newline: false
  `chsh -s $(which zsh)`
  Logger.log ' Done.'.success
  Logger.log 'Please notice: In order to use the new shell, you have to logout and back in.'.accent
end

def tabula_rasa
  # TODO: add here and then remove separate shell script file
end

# only run installation if script is invoked directly and not by requiring it
install if __FILE__ == $PROGRAM_NAME
