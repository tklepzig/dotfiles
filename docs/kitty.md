# tmux in kitty

Before opening a tmux session in a kitty terminal, you have to close all other sessions in other terminal emulators
since kitty has its own terminfo file called `xterm-kitty` and tmux does not support multiple terminfo.

> See https://github.com/kovidgoyal/kitty/issues/1241#issuecomment-568147090.

# ssh in kitty

If starting tmux on a remote server (via ssh) crashes then you need the terminfo file `xterm-kitty` on that server.
Run the following to copy the terminfo file to the remote server:

    kitty +kitten ssh user@server

> See https://sw.kovidgoyal.net/kitty/faq/#i-get-errors-about-the-terminal-being-unknown-or-opening-the-terminal-failing-when-sshing-into-a-different-computer
