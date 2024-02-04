# ToDo

- Refactor code, remove redundancy (1000 times session, window, pane args...)
- Improve send_keys abstraction (there is one raw call for the special vim
  handling)

# Get current session name

    tmux display-message -p '#S'

# Get session names

    tmux list-sessions -F "#{session_name}"

# Get window infos (-t is session name)

    tmux list-windows -t "my session" -F '#{window_active} #{window_index} #{window_zoomed_flag} #{window_layout}'

# Get pane infos (-t is session_name:window_index)

    tmux list-panes -t "my session:1" -F '#{pane_active} #{pane_index} #{pane_tty} #{pane_current_command}'

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

# Get commands in process tree for tty

    ps -t /dev/pts/5 -H -o args=
