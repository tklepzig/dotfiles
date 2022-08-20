#!/usr/bin/env ruby
# frozen_string_literal: true

DOTFILES_PATH ||= "#{ENV['HOME']}/.dotfiles-ruby"

def program_installed?(program)
  result = `sh -c 'command -v #{program}'`
  return true unless result.empty?

  false
end

unless program_installed?('git')
  p 'Error, no git found.'
  return
end

puts "Cloning repo to #{DOTFILES_PATH}..."
# `rm -rf #{DOTFILES_PATH}`
# `git clone --depth=1 https://github.com/tklepzig/dotfiles.git #{DOTFILES_PATH} > /dev/null 2>&1`
puts 'Done.'
puts 'Continue with install script...'

# require "#{DOTFILES_PATH}/install"
