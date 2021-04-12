let mapleader = "\<space>"

" Remap Ctrl+C to Escape to ensure triggering InsertLeave
map <C-c> <esc>
imap <C-c> <esc><esc>
imap jj <esc><esc>
nmap <leader>jj <esc>

nmap <Leader>w <C-w>
nmap <Leader>w<Tab> <C-w><C-p>
nnoremap <leader>b :ls<cr>:b<space>
nnoremap <leader>B :ls!<cr>:b<space>
nnoremap <Leader>q :bd<CR>
nnoremap <Leader>Q :%bd\|e#\|bd#<CR>
nnoremap <leader><Tab> :b#<cr>
nnoremap <leader><BS> :noh<cr>
nmap H ^
vmap H ^
nmap L $
vmap L $

nmap <leader>w1 :1wincmd w<cr>
nmap <leader>w2 :2wincmd w<cr>
nmap <leader>w3 :3wincmd w<cr>
nmap <leader>w4 :4wincmd w<cr>
nmap <leader>w5 :5wincmd w<cr>
nmap <leader>w6 :6wincmd w<cr>
nmap <leader>w7 :7wincmd w<cr>
nmap <leader>w8 :8wincmd w<cr>
nmap <leader>w9 :9wincmd w<cr>

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

nmap <S-j> 3<C-e>
nmap <S-k> 3<C-y>

" make search results appear in the middle of the screen
:nnoremap n nzz
:nnoremap N Nzz
:nnoremap * *zz
:nnoremap # #zz
:nnoremap g* g*zz
:nnoremap g# g#zz

" List contents of all registers (that typically contain pasteable text) (from https://superuser.com/a/656954)
nnoremap <silent> "" :registers 0123456789abcdefghijklmnopqrstuvwxyz<CR>

nnoremap <leader>u :UndotreeToggle \| UndotreeFocus<CR>

nnoremap <silent> <leader>dr :%SourceSelection<cr>
vnoremap <silent> <leader>dr :SourceSelection<cr>
