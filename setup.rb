#!/usr/bin/env ruby
# frozen_string_literal: true

# neeeded for $CHILD_STATUS and $PROGRAM_NAME
require 'English'
require 'yaml'

DF_REPO ||= ENV['DOTFILES_REPO'] || 'tklepzig/dotfiles'
DF_BRANCH ||= ENV['DOTFILES_BRANCH'] || nil
HOME ||= ENV['HOME']
DF_VARIANT ||= ENV['DOTFILES_VARIANT'] || 'full'
DF_THEME ||= ENV['DOTFILES_THEME']
DF_PATH ||= "#{HOME}/.dotfiles".freeze
DF_LOCAL_PATH ||= "#{HOME}/.dotfiles-local".freeze

module Logger
  @level = 0

  def self.log(message)
    prefix = @level.zero? ? "\e[1;34m\u276f " : ''
    message = message.rjust(message.length + 2 * @level)
    puts "#{prefix}\e[0;34m#{message}\e[0m"

    return unless block_given?

    @level += 1
    yield
    @level -= 1
    @level = 0 if @level.negative?
  end

  def self.success(message)
    prefix = @level.zero? ? "\e[1;36m\u276f " : ''
    message = message.rjust(message.length + 2 * @level)
    puts "#{prefix}\e[0;36m#{message}\e[0m"
  end

  def self.error(message)
    prefix = @level.zero? ? "\e[1;31m\u276f " : ''
    message = message.rjust(message.length + 2 * @level)
    puts "#{prefix}\e[0;31m#{message}\e[0m"
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

def migrate_local_dir(old, new)
  return unless Dir.exist?(old)

  Logger.log "Migrating '#{old}' to '#{new}'"
  `mv #{old} #{new}`
end

def migrate_local_file(old, new)
  return unless File.exist?(old)

  Logger.log "Migrating '#{old}' to '#{new}'"
  `mv #{old} #{new}`
end

def migrate_local_entries
  migrate_local_file "#{HOME}/.df-post-install", "#{DF_LOCAL_PATH}/post-install"
  migrate_local_file "#{HOME}/.plugins.custom.vim", "#{DF_LOCAL_PATH}/plugins.vim"
  migrate_local_file "#{HOME}/.df-tmux-sessions.json", "#{DF_LOCAL_PATH}/tmux-sessions.json"
  migrate_local_dir "#{HOME}/.local-scripts", "#{DF_LOCAL_PATH}/scripts"
  migrate_local_dir "#{HOME}/.zsh-sounds", "#{DF_LOCAL_PATH}/sounds"
  migrate_local_dir "#{HOME}/vim-quick-memo", "#{DF_LOCAL_PATH}/quick-memo"
end

def find_override(file_path)
  return "#{file_path}.override" if File.exist?("#{file_path}.override")

  override_before_extension = file_path.gsub(/(.*)(\..+)$/, '\1.override\2')
  override_before_extension if File.exist?(override_before_extension)
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
  Logger.log "Searching for #{program}" do
    unless program_installed? program
      Logger.error 'Not found, aborting'
      exit(false)
    end

    path = `which #{program}`
    Logger.success "Found: #{path.strip}."
  end
end

def check_optional_installation(program, install_name = program)
  Logger.log "Searching for #{program}" do
    if program_installed? program
      path = `which #{program}`
      Logger.success "Found: #{path.strip}."
    else
      Logger.error "Not Found. (Try \"sudo pacman -S #{install_name}\")"
    end
  end
end

def remove_links(pattern, file)
  return unless File.exist?(file)

  Logger.log "Removing pattern '#{pattern}' from #{file}"
  `sed "/#{pattern}/d" #{file} > #{file}.tmp && mv #{file}.tmp #{file}`
end

def write_link(link, file, command = 'source')
  `grep -q #{link} #{file}`
  return if $CHILD_STATUS.success?

  Logger.log "Adding '#{link}' to #{file}"
  File.open(file, 'a') do |f|
    f.puts "#{command} #{link}"
  end
end

def add_link_with_override(link, file, command = 'source')
  File.new(file, 'w') unless File.exist?(file)

  write_link(link, file, command)

  override = find_override(link)
  return unless override

  write_link(override, file, command)
end

def link_vim_plugins(variant)
  if File.exist?("#{DF_PATH}/vim/#{variant}/plugins.override.vim")
    merge("#{DF_PATH}/vim/#{variant}/plugins.vim",
          "#{DF_PATH}/vim/#{variant}/plugins.override.vim")
  end

  `sed 's/\\"pluginfile/source $HOME\\/.dotfiles\\/vim\\/#{variant}\\/plugins.vim\\
\\"pluginfile/g' #{DF_PATH}/vim/plugins.vim > #{DF_PATH}/vim/plugins.vim.tmp && mv #{DF_PATH}/vim/plugins.vim.tmp #{DF_PATH}/vim/plugins.vim`
end

def cleanup_vim
  Logger.log 'Cleanup vim' do
    require "#{DF_PATH}/vim/basic/uninstall.rb"
    return unless DF_VARIANT == 'full'

    require "#{DF_PATH}/vim/full/uninstall.rb"
  end
end

def setup_vim(variant)
  Logger.log "Setup#{variant == 'basic' ? ' basic' : ''} vim" do
    link_vim_plugins 'basic'
    add_link_with_override "#{DF_PATH}/vim/basic/vimrc", "#{HOME}/.vimrc"
    require "#{DF_PATH}/vim/basic/install.rb"

    return unless variant == 'full'

    link_vim_plugins 'full'
    add_link_with_override "#{DF_PATH}/vim/full/vimrc", "#{HOME}/.vimrc"
    require "#{DF_PATH}/vim/full/install.rb"
  end
end

def link_docs(path)
  return unless Dir.exist?(File.join(path, 'docs'))

  Logger.log 'Linking docs'
  Dir.glob(File.join(path, 'docs', '*')) do |file|
    `ln -sf "#{file}" "#{DF_PATH}/toolbox/docs"`
  end
end

def link_scripts(path)
  if Dir.exist?(File.join(path, 'scripts'))
    Logger.log 'Linking scripts'
    Dir.glob(File.join(path, 'scripts', '*')) do |file|
      next if ['_info.yaml'].include?(File.basename(file))

      `ln -sf "#{file}" "#{DF_PATH}/toolbox/scripts"`
    end
  end

  return unless File.exist?(File.join(path, 'scripts', '_info.yaml'))

  Logger.log 'Merging _info.yaml'
  infos = YAML.load_file("#{DF_PATH}/toolbox/scripts/_info.yaml")
  infos_include = YAML.load_file(File.join(path, 'scripts', '_info.yaml'))
  File.write("#{DF_PATH}/toolbox/scripts/_info.yaml", infos.merge(infos_include).to_yaml)
end

def add_toolbox_includes
  toolbox_includes = "#{DF_LOCAL_PATH}/toolbox-include.yaml"
  return unless File.exist?(toolbox_includes)

  Logger.log 'Processing includes'
  YAML.load_file(toolbox_includes).each do |raw_path|
    path = File.expand_path(raw_path, DF_LOCAL_PATH)
    next unless Dir.exist?(path)

    Logger.log raw_path do
      if Dir.exist?(File.join(path, '.git'))
        Logger.log 'Found git repo, updating'
        `cd "#{path}" && git fetch > /dev/null && git merge > /dev/null`
      end

      link_docs(path)
      link_scripts(path)
    end
  end
end

# TODO: clean up, split into smaller chunks, don't do all of this for basic variant
def install(variant = DF_VARIANT)
  check_mandatory_installation 'git'
  check_mandatory_installation 'zsh'

  check_optional_installation 'eza'
  check_optional_installation 'tmux'
  check_optional_installation 'lynx'

  if Dir.exist?(DF_PATH)
    Logger.log "Found existing dotfiles in #{DF_PATH}, updating"
    Dir.chdir(DF_PATH) do
      current_hash = `git rev-parse --short HEAD`.strip

      # Set the branch if it is defined
      `git remote set-branches origin #{DF_BRANCH}` if DF_BRANCH

      # Update repo
      `git fetch --depth=1 > /dev/null 2>&1`

      # Remove tracked changes
      `git reset --hard origin/#{DF_BRANCH || 'master'} > /dev/null 2>&1`

      # Checkout branch if it is defined
      if DF_BRANCH
        Logger.success "Switching to branch #{DF_BRANCH}"
        `git checkout --quiet #{DF_BRANCH}`
      end

      Logger.success "Updated dotfiles from #{current_hash} to #{`git rev-parse --short HEAD`.strip}."

      # Remove ignored changes
      # Do not remove ignored changes, e.g. to keep generated certificates
      # `git clean -fx > /dev/null 2>&1`
    end
  else
    Logger.log "Cloning repo from #{DF_REPO} to #{DF_PATH}"
    Logger.success "Switching to branch #{DF_BRANCH}" if DF_BRANCH
    `git clone --quiet --depth=1#{DF_BRANCH ? " -b #{DF_BRANCH}" : ''} https://github.com/#{DF_REPO}.git #{DF_PATH}`

    Dir.chdir(DF_PATH) do
      Logger.success "Installed dotfiles at #{`git rev-parse --short HEAD`.strip}."
    end
  end

  # Update chosen variant in .zshrc
  `sed "/DOTFILES_VARIANT/d" #{HOME}/.zshrc > #{HOME}/.zshrc.tmp && mv #{HOME}/.zshrc.tmp #{HOME}/.zshrc`
  File.open("#{HOME}/.zshrc", 'a') do |f|
    f.puts "export DOTFILES_VARIANT='#{variant}'"
  end

  `mkdir -p #{DF_LOCAL_PATH}`
  migrate_local_entries

  Logger.log "Using theme #{ENV['DOTFILES_THEME']}" if ENV['DOTFILES_THEME']
  `#{DF_PATH}/toolbox/scripts/set-theme`

  add_link_with_override "#{DF_PATH}/colours.vim", "#{HOME}/.vimrc"
  add_link_with_override "#{DF_PATH}/colours.zsh", "#{HOME}/.zshrc"
  add_link_with_override "#{DF_PATH}/colours.zsh", "#{HOME}/.tmux.conf"

  # TODO: part of vim setup, move into one block
  Logger.log 'Configuring for neovim' if ENV['DOTFILES_NVIM']

  unless File.exist?("#{DF_LOCAL_PATH}/plugins.vim")
    File.write("#{DF_LOCAL_PATH}/plugins.vim",
               "\"Plug 'any/vim-plugin'")
  end

  add_link_with_override "#{DF_PATH}/vim/plugins.vim", "#{HOME}/.vimrc"

  setup_vim(variant)

  # TODO: move before vim setup
  add_link_with_override "#{DF_PATH}/zsh/zshrc", "#{HOME}/.zshrc"

  unless File.exist?("#{HOME}/.bc")
    Logger.log 'Configuring bc'
    File.write("#{HOME}/.bc", "scale=2\n")
  end

  Logger.log 'Configuring ruby' do
    Logger.log 'Symlinking default gems configuration'
    `ln -sf #{DF_PATH}/ruby/default-gems #{HOME}/.default-gems`
    Logger.log 'Symlinking rubocop configuration'
    `ln -sf #{DF_PATH}/ruby/rubocop.yml #{HOME}/.rubocop.yml`
  end

  Logger.log 'Initializing toolbox' do
    # TODO: Only when in full mode?
    add_link_with_override "#{DF_PATH}/toolbox/init.zsh", "#{HOME}/.zshrc"
    add_toolbox_includes
  end

  # TODO: part of vim setup
  unless File.exist?("#{HOME}/.vim/autoload/plug.vim")
    Logger.log 'Installing vim-plug'
    `curl -fLo #{HOME}/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim>/dev/null 2>&1`
  end

  Logger.log 'Installing and updating vim plugins'
  # We can't rely on aliases since the subshell from ruby spawns a sh and has no idea about zsh aliases
  vim_binary = ENV['DOTFILES_NVIM'] ? 'nvim' : 'vim'

  # "echo" to suppress the "Please press ENTER to continue...
  `echo | #{vim_binary} +PlugInstall +PlugUpdate +qall > /dev/null 2>&1`

  if variant == 'full'
    # The coc plugin is installed
    Logger.log 'Updating coc extensions'
    `echo | #{vim_binary} +CocUpdateSync +qall > /dev/null 2>&1`
  end

  Logger.log 'Configuring tmux' do
    # TODO: move up into one block of "linking"
    if OS.mac?
      Logger.log 'Symlinking tmux variables for macOS'
      add_link_with_override "#{DF_PATH}/tmux/vars.osx.conf", "#{HOME}/.tmux.conf"
    else
      Logger.log 'Symlinking tmux variables for Linux'
      add_link_with_override "#{DF_PATH}/tmux/vars.linux.conf", "#{HOME}/.tmux.conf"
    end
    Logger.log 'Symlinking tmux main configuration'
    add_link_with_override "#{DF_PATH}/tmux/tmux.conf", "#{HOME}/.tmux.conf"
  end

  if program_installed? 'kitty'
    Logger.log 'Configuring kitty'
    add_link_with_override "#{DF_PATH}/kitty/kitty.conf", "#{HOME}/.config/kitty/kitty.conf", 'include'
    add_link_with_override "#{DF_PATH}/kitty/kitty.theme.conf", "#{HOME}/.config/kitty/kitty.conf", 'include'

    # Open kitty in fullscreen mode, the macos way
    # `ln -sf #{DF_PATH}/kitty/macos-launch-services-cmdline #{HOME}/.config/kitty/macos-launch-services-cmdline` if OS.mac?
  end

  if program_installed? 'ranger'
    Logger.log 'Configuring ranger'
    `mkdir -p #{HOME}/.config/ranger`
    `ln -sf #{DF_PATH}/ranger/rc.conf #{HOME}/.config/ranger/rc.conf`
  end

  if program_installed? 'i3'
    Logger.log 'Configuring i3' do
      Logger.log 'Symlinking i3 main configuration'
      add_link_with_override "#{DF_PATH}/i3/config", "#{HOME}/.config/i3/config", 'include'

      Logger.log 'Symlinking i3blocks configuration'
      `mkdir -p #{HOME}/.config/i3blocks`
      `ln -sf #{DF_PATH}/i3/i3blocks.config #{HOME}/.config/i3blocks/config`

      # `mkdir -p #{HOME}/.config/i3status`
      # `ln -sf #{DF_PATH}/i3/i3status.config #{HOME}/.config/i3status/config`

      Logger.log 'Symlinking dunst configuration'
      `mkdir -p #{HOME}/.config/dunst`
      `ln -sf #{DF_PATH}/i3/dunst.config #{HOME}/.config/dunst/dunstrc`

      Logger.log 'Symlinking picom configuration'
      `mkdir -p #{HOME}/.config/picom`
      `ln -sf #{DF_PATH}/i3/picom.config #{HOME}/.config/picom/picom.conf`
    end
  end

  if OS.mac?
    Logger.log 'Configuring aerospace for macOS'
    `ln -sf #{DF_PATH}/aerospace/config.toml #{HOME}/.aerospace.toml`
  end

  unless Dir.exist?("#{HOME}/.fzf")
    Logger.log 'Installing fzf'
    `git clone --depth 1 https://github.com/junegunn/fzf.git #{HOME}/.fzf > /dev/null 2>&1`
    `#{HOME}/.fzf/install --all > /dev/null 2>&1`
  end

  Logger.log 'Configuring Git'
  `#{DF_PATH}/git/install`

  if program_installed? 'docker'
    Logger.log 'Installing docker completion'
    `mkdir -p #{HOME}/.zsh/completion`
    `curl -L https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker > #{HOME}/.zsh/completion/_docker 2>/dev/null`
    `curl -L https://raw.githubusercontent.com/docker/compose/master/contrib/completion/zsh/_docker-compose > #{HOME}/.zsh/completion/_docker-compose 2>/dev/null`
  end

  default_shell = if OS.mac?
                    `dscl . -read #{HOME}/ UserShell | sed 's/UserShell: //'`
                  else
                    `grep ^$(id -un): /etc/passwd | cut -d : -f 7-`
                  end

  if default_shell != `which zsh`
    Logger.log 'Setting default shell to zsh' do
      `chsh -s $(which zsh)`
      Logger.log 'Please notice: In order to use the new shell, you have to logout and back in.'
    end
  end

  post_install_script = "#{DF_LOCAL_PATH}/post-install"
  if File.exist?(post_install_script) && File.executable?(post_install_script)
    Logger.log 'Running post install script' do
      result = `#{post_install_script}`
      result.split(/\n/).each { |line| Logger.log line }
    end
  end

  Logger.success 'Setup done.'
end

def uninstall
  remove_links '\.dotfiles', '.zshrc'
  remove_links '\.fzf', '.zshrc'
  remove_links "\.dotfiles", '.vimrc'
  remove_links "\.dotfiles", '.tmux.conf'
  remove_links "\.dotfiles", '.config/kitty/kitty.conf'

  # Remove fzf to ensure that the fzf include is added during install again after all dotfiles zsh includes
  Logger.log 'Removing fzf'
  `rm -rf #{HOME}/.fzf`

  Logger.log 'Removing vim-plug and vim plugins'
  `rm -f #{HOME}/.vim/autoload/plug.vim`
  `rm -rf #{HOME}/.vim/vim-plug`

  cleanup_vim

  Logger.log 'Removing bc configuration'
  `rm -f #{HOME}/.bc`

  Logger.log 'Removing default gems configuration'
  `rm -f #{HOME}/.default-gems`

  Logger.log 'Removing rubocop configuration'
  `rm -f #{HOME}/.rubocop.yml`

  Logger.log 'Removing git configuration'
  `#{DF_PATH}/git/uninstall`

  Logger.log 'Removing dotfiles'
  `rm -rf #{DF_PATH}`

  Logger.success 'Successfully uninstalled dotfiles'
end

if ARGV[0] == '--uninstall'
  uninstall
elsif __FILE__ == $PROGRAM_NAME
  # only run installation if script is invoked directly and not by requiring it
  ARGV[0] == '--basic' ? install('basic') : install
end
