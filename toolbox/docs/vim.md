# Vim

<!-- vim-markdown-toc GFM -->

* [Session Handling](#session-handling)
* [Spell Checking](#spell-checking)
* [Regex Samples](#regex-samples)
    * [Non-greedy regex](#non-greedy-regex)
* [Insert special characters](#insert-special-characters)
* [Visual Selection](#visual-selection)
* [Changes](#changes)
* [Search and Replace](#search-and-replace)
    * [Use any character as delimiter](#use-any-character-as-delimiter)
* [Calculations](#calculations)
* [TODO](#todo)

<!-- vim-markdown-toc -->

- [count]<leader>cc |NERDCommenterComment|
- [count]<leader>c<space> |NERDCommenterToggle|
- [count]<leader>ci |NERDCommenterInvert|
- [count]<leader>cy |NERDCommenterYank|
- [count]<leader>cu |NERDCommenterUncomment|

https://vim.fandom.com/wiki/All_the_right_moves

Move current line to line N: `:mN`

- vi( --> first level of ()
- v2i( --> parent level of ()
- v3i( --> parent parent level of ()
- v4i( --> you got it...

## Session Handling

Save session (window layout, open buffers, ...): `:mksession [<filename>]`
Restore session: `vim -S [<filename>]`  
(both commands use the default filename `Session.vim` if omitted)

List all currently used highlight groups:
`:source $VIMRUNTIME/syntax/hitest.vim`

After starting vim, open last edited file (and more when pressing keep hitting
`o`): <kbd>Ctrl</kbd> + <kbd>o</kbd> <kbd>o</kbd>

:set list --> display special chars

:set scrollbind! (alias: scb) --> Toggle sync scroll for current window

## Spell Checking

- Mark word under cursor as good and add it to your personal spellfile: `zg`
- Open list with suggestions: `z=`
- Apply first suggestion: `1z=`

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

## Regex Samples

    %s/Blubb\(\u\)/\L\1/g

Match `Blubb`, followed by a upper-case character. Will remove `Blubb` and
convert to upper-case character to lower case.

> To convert from lower-case to upper-case, use `\U`

> See https://vim.fandom.com/wiki/Changing_case_with_regular_expressions

    %s/Blubb/\=@a/g

Replace `Blubb` with contents of register `a`.

### Non-greedy regex

Non-greedy `.*`: Use `.\{-}` instead. See `:help non-greedy`.

## Insert special characters

While in insert mode, press <kbd>Ctrl</kbd> + <kbd>k</kbd> followed by a
two-char lookup code (see `:dig`)

## Visual Selection

Reselect last visual selection

    gv

Toggle between expanding selection at the end or beginning

    o

## Changes

See changes of file

    :changes

Jump between them

    g; - backwards
    g, - forwards

## Search and Replace

For every line containing "good" substitute all "bad" with "ugly". Of course,
this can be easily done in Vim.

Here’s how to do it:

    :g/good/s/bad/ugly/g

Let’s break it down:

- :g/good/ - this part will match lines containing a word "good" in the entire
  buffer.
- s/bad/ugly/g - is a substitute command which replaces "bad" with "ugly" in all
  occurrences, on previously matched lines (with the first part of the command).

Execute normal command (append `;`) on all lines which starts with `require`

    g/^require/norm A;

An `&` in your replacement pattern will insert the matched pattern into the
replacement text. For example, replace URLs with markdown syntax:

    %s/https\?.*/[&](&)/g

### Use any character as delimiter

You don't have to use `/` as delimiter, you can use any other character (except
`\`, `"` or `|`) which simplifies the usage of slashes inside the search string
(no need for escaping):

    s#foo#bar#g

## Calculations

To pipe the current line to bc and replace with it with the result, type (in
normal mode):

    .!bc

To pipe the lines that are currently selected in visual mode to bc and replace
with it with the result:

    !bc

## TODO

set textwidth gq :ce, :le, :ri

:redir @a :command :redir END

:args, :argdo, e.g. %s/repl/ace/g
