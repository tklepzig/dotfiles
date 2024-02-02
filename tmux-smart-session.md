# Idea

- Stop command and run it again when restoring
  - When pane command is vim, close with session (what if unsaved changes?)
  - When pane command is npm/node, send Ctrl-C
  - Anything else -> do nothing, warn "There are unknown commands still running"
    etc.
- Save sessions, windows, panes, layout, active session/window/pane, zoomed or
  not, etc.
- Restore all the above, rerun cmds (see above), open vims via `vs`
- Maybe also save and restore `pane_search_string`

# Get current session name

    tmux display-message -p '#S'

# Get session names

    tmux list-sessions -F "#{session_name}"

# Get window infos (-t is session name)

    tmux list-windows -t "my session" -F '#{window_active} #{window_index} #{window_zoomed_flag} #{window_layout}'

# Get pane infos (-t is session_name:window_index)

    tmux list-panes -t "my session:1" -F '#{pane_active} #{pane_index} #{pane_pid} #{pane_current_command}'

# Restore window layout

    tmux select-layout -t "my session:1" "<layout string, e.g. f9b3,174x40,0,0{87x40,0,0,716,86x40,88,0,717}>"

# Send command and press Enter

    tmux send-keys -t 1 "ls" Enter

# Send Ctrl-C

    tmux send-keys -t 1 "C-c"

# Send leader-W to (n)vim to close w/ writing session

    tmux send-keys -t 1 "Space W"

# Terminate process (last resort)

    # Terminates the program (like Ctrl+C) (notice the '-' in front of the pid)
    kill -INT -888
    # Force kill
    kill -9 888
