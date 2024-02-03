#!/usr/bin/env ruby
# frozen_string_literal: true

require 'English'
require 'json'

def session_exists?(session_name)
  `tmux has-session -t "#{session_name}" 2>/dev/null`
  $CHILD_STATUS == 0
end

def add_window(session_name, dir, active: false)
  `tmux new-window #{active ? '' : '-d'} -t "#{session_name}:" -n "" -c "#{dir}"`
end

def new_session(session_name)
  `tmux new-session -d -s "#{session_name}" -n ""`
end

def split_window(session_name, window_index, dir, active: false)
  `tmux split-window #{active ? '' : '-d'} -t "#{session_name}:#{window_index}" -c "#{dir}"`
end

def window_set_layout(session_name, window_index, layout)
  `tmux select-layout -t "#{session_name}:#{window_index}" "#{layout}"`
end

def send_keys(session_name, window_index, pane_index, keys, no_enter: false)
  `tmux send-keys -t "#{session_name}:#{window_index}.#{pane_index}" "#{keys}" #{no_enter ? '' : 'Enter'}`
end

def tty_command(tty)
  `ps -t #{tty} -H -o args=`.split(/\n/).map(&:strip).at(1)
end

def tmux_sessions
  # Comma, same issue as below...
  session_list = `tmux list-sessions -F "#\{session_name\},#\{session_attached\}"`
                 .split(/\n/)

  session_list.map do |session|
    name, attached_clients = session.split(/,/)
    [name, { active: !attached_clients.to_i.zero? }]
  end
end

def tmux_windows(session_name)
  window_list = `tmux list-windows -t "#{session_name}" -F "#\{window_index\} #\{window_active\} #\{window_zoomed_flag\} #\{window_layout\}"`
                .split(/\n/)

  window_list.map do |window|
    index, active, zoomed, layout = window.split
    [index, { active: !active.to_i.zero?, zoomed: !zoomed.to_i.zero?, layout: }]
  end
end

def tmux_panes(session_name, window_index)
  # Maybe using a comma as divider is not the best idea (thinking of filenames and paths with a comma in it)
  pane_list = `tmux list-panes -t "#{session_name}:#{window_index}" -F "#\{pane_index\},#\{pane_active\},#\{pane_tty\},#\{pane_current_path\}"`
              .split(/\n/)

  pane_list.map do |pane|
    index, active, tty, path = pane.split(/,/)
    [index, { active: !active.to_i.zero?, path:, command: tty_command(tty) }]
  end
end

def tmux_info
  sessions = tmux_sessions.map do |session|
    session_name, session_info = session

    windows = tmux_windows(session_name).map do |window|
      window_index, window_info = window

      panes = tmux_panes(session_name, window_index).map do |pane|
        pane_index, pane_info = pane

        { index: pane_index, **pane_info }
      end

      { index: window_index, **window_info, panes: }
    end

    { name: session_name, **session_info, windows: }
  end

  { sessions: }
end

def restore_panes(session, window)
  panes = window['panes']

  panes.each_with_index do |pane, index|
    split_window(session['name'], window['index'], pane['path'], active: pane['active']) unless index.zero?
    start_command(session, window, pane)
    window_set_layout(session['name'], window['index'], window['layout'])
  end

  return unless window['zoomed']

  # zooming can only be done when all panes are created
  # (imagine zooming a single pane in a window, that makes no sense...)
  panes.filter { |pane| pane['active'] }.each do |pane|
    `tmux resize-pane -t "#{session['name']}":#{window['index']}.#{pane['index']} -Z`
  end
end

def restore_windows(session)
  windows = session['windows']
  windows.each do |window|
    if session_exists? session['name']
      add_window(session['name'], window['panes'].first['path'], active: window['active'])
    else
      new_session(session['name'])
      # Don't use new-session's -c option to set the initial directory, use cd instead
      # Reason: new-session's -c option sets the initial directory for all windows, not just the first one
      send_keys(session['name'], window['index'], 1, "cd '#{window['panes'].first['path']}' && clear")
    end

    restore_panes(session, window)
  end
end

def restore(sessions)
  sessions['sessions'].each do |session|
    restore_windows(session)
  end

  `tmux attach -t #{sessions['sessions'].filter { |session| session['active'] }.first['name']}`
end

def start_command(session, window, pane)
  return if pane['command'].nil? || pane['command'].include?($PROGRAM_NAME)

  send_keys(session['name'], window['index'], pane['index'], pane['command'])
end

def kill_command(session, window, pane)
  return if pane['command'].nil? || pane['command'].include?($PROGRAM_NAME)

  send_keys(session['name'], window['index'], pane['index'], 'C-c', no_enter: true)
end

def close_all(sessions)
  sessions['sessions'].each do |session|
    session['windows'].reverse.each do |window|
      window['panes'].reverse.each do |pane|
        kill_command(session, window, pane)
        send_keys(session['name'], window['index'], pane['index'], 'exit')
      end
    end
  end
end

action = ARGV[0]

case action
when 's'
  File.write('./sessions.json', tmux_info.to_json)
  # puts JSON.pretty_generate(tmux_info)
  close_all(JSON.parse(File.read('./sessions.json')))
when 'r'
  if ENV['TMUX']
    puts 'A tmux session is already running, aborting.'
    exit 1
  end
  restore(JSON.parse(File.read('./sessions.json')))
end
