let mapleader = "\<space>"

" Remap Ctrl+C to Escape to ensure triggering InsertLeave
noremap <C-c> <esc>
inoremap <C-c> <esc><esc>

inoremap jj <esc><esc>

nmap <Leader>w <C-w>

nnoremap <silent> <Leader>wz :<C-U>execute 'resize ' . (v:count ? v:count : '')<cr>
nnoremap <silent> <Leader>wZ :<C-U>execute 'vertical resize ' . (v:count ? v:count : '')<cr>
nnoremap <Leader>w<Tab> :wincmd p<cr>
nnoremap <Leader>q :bunload<CR>
nnoremap <leader>W :mksession!\|:wqa<cr>
nnoremap <leader>Q :qa<cr>
nnoremap <leader>X :qa!<cr>
"removes all buffers, not really used
"nnoremap <Leader>Q :%bd\|e#\|bd#<CR>
nnoremap <leader>1 :b#<cr>
nnoremap <leader><BS> :noh<cr>
nmap H ^
vmap H ^
nmap L $
vmap L $
vnoremap <silent> P "0p
nnoremap <leader>$ :shell<cr>

" easier execution of macros
nmap <BS> @
nmap <BS><BS> @@
vmap <BS> @
vmap <BS><BS> @@

" see :help Y
map Y y$

nnoremap <silent> <leader>! :ExecuteSelection<cr>
vnoremap <silent> <leader>! :ExecuteSelection<cr>

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

nnoremap <leader>- <C-o>
nnoremap <leader>+ <C-i>

" Enter // to search for currently visually selected block
" Hint: enter :g/ (short for :g//p) to list all  occurences in the current file
vnoremap // y/\V<C-r>=escape(@",'/\')<CR><CR>

nnoremap M J
vnoremap M J

nnoremap J 3<C-e>
vnoremap J 3<C-e>

nnoremap K 3<C-y>
vnoremap K 3<C-y>

" List contents of all registers (that typically contain pasteable text) (from https://superuser.com/a/656954)
nnoremap <silent> "" :registers 0123456789abcdefghijklmnopqrstuvwxyz<CR>

" List all custom marks
nnoremap <silent> '' :marks abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ<CR>

" List only custom global marks
nnoremap <silent> ,, :marks ABCDEFGHIJKLMNOPQRSTUVWXYZ<CR>

" Easier jumping to global marks
nnoremap <silent> ,a `A
nnoremap <silent> ,b `B
nnoremap <silent> ,c `C
nnoremap <silent> ,d `D
nnoremap <silent> ,e `E
nnoremap <silent> ,f `F
nnoremap <silent> ,g `G
nnoremap <silent> ,h `H
nnoremap <silent> ,i `I
nnoremap <silent> ,j `J
nnoremap <silent> ,k `K
nnoremap <silent> ,l `L
nnoremap <silent> ,m `M
nnoremap <silent> ,n `N
nnoremap <silent> ,o `O
nnoremap <silent> ,p `P
nnoremap <silent> ,q `Q
nnoremap <silent> ,r `R
nnoremap <silent> ,s `S
nnoremap <silent> ,t `T
nnoremap <silent> ,u `U
nnoremap <silent> ,v `V
nnoremap <silent> ,w `W
nnoremap <silent> ,x `X
nnoremap <silent> ,y `Y
nnoremap <silent> ,z `Z

nnoremap <leader>u :UndotreeToggle \| UndotreeFocus<CR>

function! s:BigSmallWin()
  wincmd =
  let width = winwidth(0)
  execute 'vertical resize ' . float2nr(width + width * 0.2)
endfunction
nnoremap <silent> <Leader>w# :call <SID>BigSmallWin()<cr>

nnoremap <silent> <leader>m :QuickMemo<cr>
nnoremap <silent> <leader>M :QuickMemo git<cr>


if !empty($DOTFILES_NVIM) && has('nvim')
  tnoremap <Esc> <C-\><C-n>
  tnoremap jj <C-\><C-n>
  nnoremap <leader>$ :terminal<cr>i
endif
