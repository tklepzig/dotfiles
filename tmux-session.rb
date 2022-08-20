#!/usr/bin/env ruby
# frozen_string_literal: true

require 'English'
require 'csv'

# TODO: persist and restore the state & position of panes.

action = ARGV[0]

def session_exists?(session_name)
  `tmux has-session -t "#{session_name}" 2>/dev/null`
  $CHILD_STATUS == 0
end

def add_window(session_name, window_name, dir)
  `tmux new-window -d -t "#{session_name}:" -n "#{window_name}" -c "#{dir}"`
end

def new_session(session_name, window_name, dir)
  `cd "#{dir}" && tmux new-session -d -s "#{session_name}" -n "#{window_name}"`
end

def save
  tmux_windows = `tmux list-windows -a -F "#S,#W,#\{pane_current_path\}"`
  File.open("#{ENV['HOME']}/.tmux-session", 'w') do |f|
    f.puts tmux_windows
  end
end

def restore
  `tmux start-server`

  CSV.read("#{ENV['HOME']}/.tmux-session").each do |tmux_window|
    session_name, window_name, dir = tmux_window
    next unless File.directory? dir

    if session_exists? session_name
      add_window(session_name, window_name, dir)
    else
      new_session(session_name, window_name, dir)
    end
  end
end

def help
  puts "Usage: #{$PROGRAM_NAME} [save|restore]"
  exit 1
end

case action
when 'save'
  save
when 'restore'
  restore
else
  help
end
