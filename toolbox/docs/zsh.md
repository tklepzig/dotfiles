Find key code for binding:

<kbd>Ctrl</kbd>+<kbd>v</kbd> KEY

or run

    cat -v

and press the desired key(s)

Home, End and Delete does not work as expected? -> Add the following to `.zshrc`:

    bindkey '\e[H'  beginning-of-line
    bindkey '\e[F'  end-of-line
    bindkey '\e[3~' delete-char

    # inside tmux the keycodes differ for whatever reason...
    bindkey '\e[1~'  beginning-of-line
    bindkey '\e[4~'  end-of-line

### Brace Expansion (Create Range)

    echo _{blubb,blabb,foo,bar} --> _blubb,_blabb,_foo,_bar
    echo {a..z} --> a,b,...,z
    echo {0..10} --> 0,1,...,10
    echo {00..10} --> 00,01,02,...,10
    echo pre{0..10}suf --> pre0suf,pre1suf,...,pre10suf
    echo {a..z}{0..10} --> a0,a1,...,z10
    touch {a-z}.mp3
    # When using variables, the command have to be evaluated twice, using eval
    eval echo {$a..$b}

> works in bash as well

> See https://wiki.bash-hackers.org/syntax/expansion/brace
