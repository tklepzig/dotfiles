set nocompatible
set softtabstop=2 expandtab shiftwidth=2 smarttab

" Enable syntax highlighting.
syntax on

" File-type highlighting and configuration.
" Run :filetype (without args) to see what you may have
" to turn on yourself, or just set them all to be sure.
filetype on
filetype plugin on
filetype indent on

set autoindent smartindent
set showmode

" Show line numbers.
set number

" Do not wrap lines.
set nowrap

" Show matching brackets.
set showmatch

" Always show status line.
set laststatus=2

" Mouse in all modes
set mouse=a

set history=1000
set matchtime=0
" The “Press ENTER or type command to continue” prompt is jarring and usually unnecessary. You can shorten command-line text and other info tokens with.
set shortmess=atI


" Now in the bottom right corner of the status line there will be something like: 529, 35 68%, representing line 529, column 35, about 68% of the way to the end.
set ruler
set showcmd

" A running gvim will always have a window title, but when vim is run within an xterm, by default it inherits the terminal’s current title.
set title


" Search options
" Highlight search terms
set hlsearch
set incsearch
set ignorecase
set smartcase


" Blink if there is an error
set visualbell
set noerrorbells
set printoptions=paper:letter

" Make backspace delete lots of things
set backspace=indent,eol,start

" Auto-backup files and .swp files don't go to pwd
set backupdir=$TEMP,.
set directory=$TEMP,.

set backspace=2   " Backspace deletes like most programs in insert mode

set magic
