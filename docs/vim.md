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

:set list --> display special chars

# Spell Checking

See also `:help spell`

Enable:

```
:setlocal spell spelllang=en
```

Mark word under cursor as good and add it to your personal spellfile: `zg`
Open list with suggestions: `z=`
Apply first suggestion: `1z=`

Diff two files byte-wise

    xxd file1 > file1.hex
    xxd file2 > file2.hex
    vimdiff file1.hex file2.hex

Edit file in hex mode

    :%!xxd

> Back to text
>
>     :%!xxd -r
>
> Use hex syntax highlighting
>
>     :set ft=xxd

TODO
map toggle setlocal spell
map next misspelled word
map prev misspelled word
