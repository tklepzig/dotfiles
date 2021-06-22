[count]<leader>cc |NERDCommenterComment|
[count]<leader>c<space> |NERDCommenterToggle|
[count]<leader>ci |NERDCommenterInvert|
[count]<leader>cy |NERDCommenterYank|
[count]<leader>cu |NERDCommenterUncomment|

https://vim.fandom.com/wiki/All_the_right_moves

Move current line to line N: `:mN`

vi( --> first level of ()
v2i( --> parent level of ()
v3i( --> parent parent level of ()
v4i( --> you got it...

# Session Handling

Save session (window layout, open buffers, ...): `:mksession [<filename>]`
Restore session: `vim -S [<filename>]`
(both commands use the default filename `Session.vim` if omitted)

List all currently used highlight groups: `:source $VIMRUNTIME/syntax/hitest.vim`

After starting vim, open last edited file (and more when pressing keep hitting `o`): <kbd>Ctrl</kbd> + <kbd>o</kbd> <kbd>o</kbd>
