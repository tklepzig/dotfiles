NOTE: The make tool reads the makefile and checks the modification time-stamps of the files at both the side of ':' symbol in a rule.

Example
In a directory 'test' following files are present:

    prerit@vvdn105:~/test$ ls
    hello  hello.c  makefile

In makefile a rule is defined as follows:

    hello:hello.c
        cc hello.c -o hello

Now assume that file 'hello' is a text file containing some data, which was created after 'hello.c' file. So the modification (or creation) time-stamp of 'hello' will be newer than that of the 'hello.c'. So when we will invoke 'make hello' from command line, it will print as:

    make: 'hello' is up to date.

Now access the 'hello.c' file and put some white spaces in it, which doesn't affect the code syntax or logic then save and quit. Now the modification time-stamp of hello.c is newer than that of the 'hello'. Now if you invoke 'make hello', it will execute the commands as:

    cc hello.c -o hello

And the file 'hello' (text file) will be overwritten with a new binary file 'hello' (result of above compilation command).

If we use .PHONY in makefile as follow:

    .PHONY:hello

    hello:hello.c
        cc hello.c -o hello

and then invoke 'make hello', it will ignore any file present in the pwd 'test' and execute the command every time.

Now suppose, that 'hello' target has no dependencies declared:

    hello:
        cc hello.c -o hello

and 'hello' file is already present in the pwd 'test', then 'make hello' will always show as:

    make: 'hello' is up to date.
