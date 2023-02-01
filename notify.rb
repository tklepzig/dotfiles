#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative './setup'

player = if OS.mac?
           'afplay -v 0.2'
         else
           'aplay'
         end
exit(false) unless program_installed? player.split(/\s/).first

sound_path = "#{HOME}/.zsh-sounds/notify.wav"
exit(false) unless File.exist? sound_path

`#{player} #{sound_path}`
