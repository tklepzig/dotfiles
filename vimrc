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

let mapleader = "\<space>"

" Remap Escape key to qq
"inoremap qq <ESC>

" Remap autocompletion trigger to Ctrl+Space
" inoremap <Nul> <C-n>

" new

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

"Plugin 'HerringtonDarkholme/yats.vim'
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
Plugin 'scrooloose/nerdtree.git'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'kien/ctrlp.vim'
Plugin 'tomasiser/vim-code-dark'
Plugin 'tpope/vim-fugitive'
Plugin 'junegunn/gv.vim'
"Plugin 'rickhowe/diffchar.vim'
Plugin 'airblade/vim-gitgutter'
Plugin 'ianks/vim-tsx'
Plugin 'Quramy/tsuquyomi'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
"Plugin 'christoomey/vim-tmux-navigator'
Plugin 'scrooloose/nerdcommenter'
Plugin 'sheerun/vim-polyglot'
Plugin 'leafgarland/typescript-vim'
Plugin 'tpope/vim-surround'
Plugin 'maralla/completor.vim'
Plugin 'BrandonRoehl/auto-omni'
Plugin 'josudoey/vim-eslint-fix'
Plugin 'w0rp/ale'
Plugin 'alvan/vim-closetag'
Plugin 'jiangmiao/auto-pairs'
Plugin 'dyng/ctrlsf.vim'
Plugin '1995parham/vim-zimpl'
Plugin 'Yggdroot/indentLine'
Plugin 'gcmt/wildfire.vim'

call vundle#end()

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
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | wincmd p | endif

" Open NERD Tree when no file specified.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

map <Leader>n :NERDTreeToggle<CR>
map <Leader>nf :NERDTreeFind<CR>

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


nnoremap <Leader>w <C-w>
nnoremap <Enter> O<Esc>j

map <Leader>p :CtrlP<CR>
map <Leader>i :TsuImport<CR>


" Go to tab by number
noremap <leader>1 1gt
noremap <leader>2 2gt
noremap <leader>3 3gt
noremap <leader>4 4gt
noremap <leader>5 5gt
noremap <leader>6 6gt
noremap <leader>7 7gt
noremap <leader>8 8gt
noremap <leader>9 :tablast<cr>

" Go to last active tab
au TabLeave * let g:lasttab = tabpagenr()
nnoremap <silent> <leader><Tab> :exe "tabn ".g:lasttab<cr>
vnoremap <silent> <leader><Tab> :exe "tabn ".g:lasttab<cr>


" TODO: Use only buffers, not tabs

" Enable the list of buffers
let g:airline#extensions#tabline#enabled = 1
"
" " Show just the filename
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#left_sep = '|'
let g:airline#extensions#tabline#left_alt_sep = '|'
let airline#extensions#tabline#tabs_label = ''
let airline#extensions#tabline#show_splits = 0

" only show tabs, no buffers
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline#extensions#tabline#show_splits = 0
let g:airline#extensions#tabline#show_tabs = 1
let g:airline#extensions#tabline#show_tab_nr = 0
let g:airline#extensions#tabline#show_tab_type = 0
let g:airline#extensions#tabline#close_symbol = '×'
let g:airline#extensions#tabline#show_close_button = 0

" no arrow keys in edit mode
inoremap <Left> <nop>
inoremap <Right> <nop>
" do not disable them here to allow them for autocompletion navigation
"inoremap <Up> <nop>
"inoremap <Down> <nop>

autocmd FileType typescript,typescript.tsx nmap <buffer> <Leader>t : <C-u>echo tsuquyomi#hint()<CR>

set omnifunc=syntaxcomplete#Complete
set completeopt=noinsert,menuone,menu

inoremap <expr> <CR>       pumvisible()    ? "\<C-y>"                  : "\<CR>"
inoremap <expr> <Down>     pumvisible()    ? "\<C-n>"                  : ""
inoremap <expr> <Up>       pumvisible()    ? "\<C-p>"                  : ""
inoremap <expr> <PageDown> pumvisible()    ? "\<PageDown>\<C-p>\<C-n>" : "\<PageDown>"
inoremap <expr> <PageUp>   pumvisible()    ? "\<PageUp>\<C-p>\<C-n>"   : "\<PageUp>"

" Allow us to use Ctrl-s and Ctrl-q as keybinds
silent !stty -ixon

" Restore default behaviour when leaving Vim.
autocmd VimLeave * silent !stty ixon

nmap <C-s> :w<CR>
imap <C-s> <C-o>:w<CR>


let g:ale_linters = {
      \   'javascript': ['eslint'],
      \   'typescript': ['tsserver', 'eslint']
      \}

let g:ale_fixers = {
      \   '*': ['remove_trailing_lines', 'trim_whitespace'],
      \    'javascript': ['eslint'],
      \    'typescript': ['eslint', 'prettier'],
      \    'scss': ['prettier'],
      \    'html': ['prettier']
      \}

let g:ale_fix_on_save = 1
nmap <C-f> :ALEFix<CR>:TsuQuickFix<CR>
imap <C-f> <C-o>:ALEFix<CR>:TsuQuickFix<CR>
let NERDTreeQuitOnOpen = 1
let NERDTreeShowHidden = 1

nnoremap <leader><Left> <C-o><CR>
nnoremap <leader><Right> <C-i><CR>

if has('macunix')
  set clipboard=unnamed
else
  set clipboard=unnamedplus
endif

nnoremap <leader>r :ALEFindReferences<CR>
nnoremap <leader>d :TsuDefinition<CR>
"todo: ale or tsu
" rename
" search in files
nnoremap <leader>gs :Gstatus<CR>
nnoremap <leader>gd :Gvdiffsplit<CR>
nnoremap <leader>gl :GV<CR>
nnoremap <leader>glf :GV!<CR>
let g:closetag_filenames = '*.html,*.xhtml,*.phtml,*.tsx, *.jsx'
" todo create ctrlsf mappings and config settings
" map to <leader>f*
nmap     <leader>f <Plug>CtrlSFPrompt
nmap     <leader>s :CtrlSFToggle<CR>
vmap     <leader>f <Plug>CtrlSFVwordExec
let g:ctrlsf_auto_close = {
      \ "normal" : 0,
      \ "compact": 0
      \}
let g:ctrlsf_default_view_mode = 'compact'

" open file with CtrlP in new tab
let g:ctrlp_prompt_mappings = {
    \ 'AcceptSelection("e")': ['<C-e>'],
    \ 'AcceptSelection("t")': ['<Cr>'],
    \ }

" from https://stackoverflow.com/a/54961319
function AleIgnore()
  let codes = []
  for d in getloclist(0)
    if (d.lnum==line('.'))
      let code = split(d.text,':')[0]
      call add(codes, code)
    endif
  endfor
  if len(codes)
    exe 'normal O/* eslint-disable-next-line ' . join(codes, ', ') . ' */'
  endif
endfunction


autocmd BufRead,BufNewFile *.zpl set filetype=zimpl

" see https://unix.stackexchange.com/a/383044
" Triger `autoread` when files changes on disk
" https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044
" https://vi.stackexchange.com/questions/13692/prevent-focusgained-autocmd-running-in-command-line-editing-mode
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif
" Notification after file change
" https://vi.stackexchange.com/questions/13091/autocmd-event-for-autoread
autocmd FileChangedShellPost *
  \ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None
