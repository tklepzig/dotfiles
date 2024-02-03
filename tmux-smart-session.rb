#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

def tty_command(tty)
  `ps -t #{tty} -H -o args=`.split(/\n/).map(&:strip).at(1)
end

def tmux_sessions
  `tmux list-sessions -F "#\{session_name\}"`.split(/\n/)
end

def tmux_windows(session_name)
  window_list = `tmux list-windows -t "#{session_name}" -F "#\{window_index\} #\{window_active\} #\{window_zoomed_flag\} #\{window_layout\}"`.split(/\n/)
  window_list.map do |window|
    index, active, zoomed, layout = window.split
    [index, { active: !active.to_i.zero?, zoomed: !zoomed.to_i.zero?, layout: }]
  end
end

def tmux_panes(session_name, window_index)
  # Maybe using a comma as divider is not the best idea (thinking of filenames and paths with a comma in it)
  pane_list = `tmux list-panes -t "#{session_name}:#{window_index}" -F "#\{pane_index\},#\{pane_active\},#\{pane_tty\},#\{pane_current_path\}"`.split(/\n/)
  pane_list.map do |pane|
    index, active, tty, path = pane.split(/,/)
    command = tty_command(tty)
    [index, { active: !active.to_i.zero?, path:, command: }]
  end
end

def tmux_info
  tmux_sessions.reduce({}) do |sessions_acc, session|
    windows = tmux_windows(session).reduce({}) do |windows_acc, window|
      window_index, window_info = window

      panes = tmux_panes(session, window_index).reduce({}) do |panes_acc, pane|
        pane_index, pane_info = pane
        panes_acc.merge(pane_index => pane_info)
      end

      windows_acc.merge({ window_index => {
                          **window_info,
                          panes:
                        } })
    end
    sessions_acc.merge({ session => { windows: } })
  end
end

def tmux_info_array
  sessions = tmux_sessions.map do |session|
    windows = tmux_windows(session).map do |window|
      window_index, window_info = window

      panes = tmux_panes(session, window_index).map do |pane|
        pane_index, pane_info = pane
        { index: pane_index, **pane_info }
      end

      { index: window_index, **window_info, panes: }
    end

    { name: session, windows: }
  end
  { sessions: }
end

puts JSON.pretty_generate(tmux_info_array)
