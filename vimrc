set nocompatible
set tabstop=2 softtabstop=2 expandtab shiftwidth=2 smarttab

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

set backupdir=/tmp//,.
set directory=/tmp//,.
set undodir=/tmp//,.

set backspace=2   " Backspace deletes like most programs in insert mode

" Remap Escape key to qq
inoremap qq <ESC>

" Remap autocompletion trigger to Ctrl+Space
inoremap <Nul> <C-n>

" new

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
Plugin 'scrooloose/nerdtree.git'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'kien/ctrlp.vim'
Plugin 'tomasiser/vim-code-dark'
Plugin 'sheerun/vim-polyglot'
Plugin 'tpope/vim-fugitive'
Plugin 'junegunn/gv.vim'
Plugin 'christoomey/vim-system-copy'
Plugin 'rickhowe/diffchar.vim'
Plugin 'airblade/vim-gitgutter'
Plugin 'leafgarland/typescript-vim'
Plugin 'ianks/vim-tsx'
Plugin 'Quramy/tsuquyomi'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'

call vundle#end()

if substitute(system('uname'), '\n', '', '') == "Linux"
  let g:system_copy#copy_command='xclip -sel clipboard'
  let g:system_copy#paste_command='xclip -sel clipboard -o'
endif

" Enable TOC window auto-fit
let g:vim_markdown_toc_autofit = 1
let g:vim_markdown_folding_disabled = 1
set nofoldenable

" NERDTress File highlighting
function! NERDTreeHighlightFile(extension, fg, bg, guifg, guibg)
 exec 'autocmd filetype nerdtree highlight ' . a:extension .' ctermbg='. a:bg .' ctermfg='. a:fg .' guibg='. a:guibg .' guifg='. a:guifg
 exec 'autocmd filetype nerdtree syn match ' . a:extension .' #^\s\+.*'. a:extension .'$#'
endfunction

call NERDTreeHighlightFile('md', 'blue', 'none', '#3366FF', '#151515')
call NERDTreeHighlightFile('yml', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('config', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('conf', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('json', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('html', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('css', 'cyan', 'none', 'cyan', '#151515')
call NERDTreeHighlightFile('js', 'Red', 'none', '#ffa500', '#151515')

colorscheme codedark
let g:airline_theme = 'codedark'

let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1

" How can I open NERDTree automatically when vim starts up on opening a directory?
" This window is tab-specific, meaning it's used by all windows in the tab. This trick also prevents NERDTree from hiding when first selecting a file.
" Note: Executing vim ~/some-directory will open NERDTree and a new edit window. exe 'cd '.argv()[0] sets the pwd of the new edit window to ~/some-directory
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif

" Open NERD Tree when no file specified.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" map Ctrl+n to toggling the NERD Tree
map <C-n> :NERDTreeToggle<CR>

" Close NERD Tree when everything else is closed.
" disabled for convenience, if closing all is desired, enter :qa
" autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Keep NERD Tree open in new tabs
" autocmd BufWinEnter * NERDTreeMirror

" Prevent Ctrlp from searching node modules and git
let g:ctrlp_custom_ignore = '\v[\/](node_modules|dist)|(\.(swp|git))$'
let g:ctrlp_show_hidden = 1

highlight GitGutterAdd    ctermfg=2
highlight GitGutterChange ctermfg=3
highlight GitGutterDelete ctermfg=1

autocmd BufNewFile,BufRead *.ts setlocal filetype=typescript

" set filetypes as typescript.tsx
autocmd BufNewFile,BufRead *.tsx set filetype=typescript.tsx

let mapleader = "\<space>"

nnoremap <Leader>w <C-w>
