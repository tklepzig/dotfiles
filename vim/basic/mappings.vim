let mapleader = "\<space>"

" Remap Ctrl+C to Escape to ensure triggering InsertLeave
noremap <C-c> <esc>
inoremap <C-c> <esc><esc>

inoremap jj <esc><esc>

nmap <Leader>w <C-w>

nnoremap <silent> <Leader>wz :<C-U>execute 'resize ' . (v:count ? v:count : '')<cr>
nnoremap <silent> <Leader>wZ :<C-U>execute 'vertical resize ' . (v:count ? v:count : '')<cr>
nnoremap <Leader>w<Tab> :wincmd p<cr>
nnoremap <leader>wQ :mksession!\|:qa<cr>
nnoremap <Leader>q :bunload<CR>
nnoremap <Leader>Q :%bd\|e#\|bd#<CR>
nnoremap <leader>1 :b#<cr>
nnoremap <leader><Tab> :BufferNavigatorToggle<cr>
nnoremap <leader><BS> :noh<cr>
nmap H ^
vmap H ^
nmap L $
vmap L $

nnoremap <leader>w1 :1wincmd w<cr>
nnoremap <leader>w2 :2wincmd w<cr>
nnoremap <leader>w3 :3wincmd w<cr>
nnoremap <leader>w4 :4wincmd w<cr>
nnoremap <leader>w5 :5wincmd w<cr>
nnoremap <leader>w6 :6wincmd w<cr>
nnoremap <leader>w7 :7wincmd w<cr>
nnoremap <leader>w8 :8wincmd w<cr>
nnoremap <leader>w9 :9wincmd w<cr>

" no arrow keys in edit mode
inoremap <Left> <nop>
inoremap <Right> <nop>
" do not disable them here to allow them for autocompletion navigation
"inoremap <Up> <nop>
"inoremap <Down> <nop>

inoremap <expr> <CR>       pumvisible()    ? "\<C-y>"                  : "\<CR>"
inoremap <expr> <Down>     pumvisible()    ? "\<C-n>"                  : ""
inoremap <expr> <Up>       pumvisible()    ? "\<C-p>"                  : ""
inoremap <expr> <PageDown> pumvisible()    ? "\<PageDown>\<C-p>\<C-n>" : "\<PageDown>"
inoremap <expr> <PageUp>   pumvisible()    ? "\<PageUp>\<C-p>\<C-n>"   : "\<PageUp>"

nnoremap <leader>s :w<CR>
nnoremap <leader>S :wa<CR>

nnoremap <leader>- <C-o><CR>
nnoremap <leader>+ <C-i><CR>

" Enter // to search for currently visually selected block
" Hint: enter :g/ (short for :g//p) to list all  occurences in the current file
vnoremap // y/\V<C-r>=escape(@",'/\')<CR><CR>

nnoremap <S-j> 3<C-e>
vnoremap <S-j> 3<C-e>

nnoremap <S-k> 3<C-y>
vnoremap <S-k> 3<C-y>

" make search results appear in the middle of the screen
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap g* g*zz
nnoremap g# g#zz

" List contents of all registers (that typically contain pasteable text) (from https://superuser.com/a/656954)
nnoremap <silent> "" :registers 0123456789abcdefghijklmnopqrstuvwxyz<CR>

nnoremap <leader>u :UndotreeToggle \| UndotreeFocus<CR>

" Jump to next/prev spell check issue
nnoremap <leader>c ]s
nnoremap <leader>C [s
