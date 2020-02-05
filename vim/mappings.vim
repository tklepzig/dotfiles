let mapleader = "\<space>"

" Remap Ctrl+C to Escape to ensure triggering InsertLeave
map <C-c> <esc>
imap <C-c> <esc><esc>
imap jj <esc><esc>
nmap <leader>jj <esc>

nnoremap <Leader>n :NERDTreeFind<CR>
nnoremap <Leader>N :NERDTreeToggle<CR>
nmap <Leader>w <C-w>
nmap <Leader>w<Tab> <C-w><C-p>
nnoremap <Leader>p :GFiles<CR>
nnoremap <Leader>P :History<CR>
nnoremap <Leader>; :Commands<CR>
nnoremap <Leader>b :Buffers<CR>
nnoremap <Leader>q :bd<CR>
nnoremap <Leader>Q :bufdo! bd<CR>
nnoremap <Leader>Qc :%bd\|e#\|bd#<CR>
nnoremap <leader><Tab> :b#<cr>
nnoremap <leader><BS> :noh<cr>
nnoremap <leader>, :VimuxPromptCommand<cr>
nnoremap <leader>vp :VimuxPromptCommand<cr>
nnoremap <leader>vl :VimuxRunLastCommand<cr>
nnoremap <leader>vi :VimuxInspectRunner<cr>
nnoremap <leader>vz :VimuxZoomRunner<cr>
nmap H ^
vmap H ^
nmap L $
vmap L $
" ToDo: Add CocList diagnostics

let g:airline#extensions#tabline#buffer_idx_mode = 1
nmap <leader>1 <Plug>AirlineSelectTab1
nmap <leader>2 <Plug>AirlineSelectTab2
nmap <leader>3 <Plug>AirlineSelectTab3
nmap <leader>4 <Plug>AirlineSelectTab4
nmap <leader>5 <Plug>AirlineSelectTab5
nmap <leader>6 <Plug>AirlineSelectTab6
nmap <leader>7 <Plug>AirlineSelectTab7
nmap <leader>8 <Plug>AirlineSelectTab8
nmap <leader>9 <Plug>AirlineSelectTab9
nmap <leader>h <Plug>AirlineSelectPrevTab
nmap <leader>l <Plug>AirlineSelectNextTab
nmap <leader><Left> <Plug>AirlineSelectPrevTab
nmap <leader><Right> <Plug>AirlineSelectNextTab

nmap <leader>w1 :1wincmd w<cr>
nmap <leader>w2 :2wincmd w<cr>
nmap <leader>w3 :3wincmd w<cr>
nmap <leader>w4 :4wincmd w<cr>
nmap <leader>w5 :5wincmd w<cr>
nmap <leader>w6 :6wincmd w<cr>
nmap <leader>w7 :7wincmd w<cr>
nmap <leader>w8 :8wincmd w<cr>
nmap <leader>w9 :9wincmd w<cr>
"" Go to last active tab
"au TabLeave * let g:lasttab = tabpagenr()
"nnoremap <silent> <leader><Tab> :exe "tabn ".g:lasttab<cr>
"vnoremap <silent> <leader><Tab> :exe "tabn ".g:lasttab<cr>

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

nnoremap <leader>- <C-o><CR>
nnoremap <leader>+ <C-i><CR>

" Plugins---------------------------------------------------------------------

" ALE
"nnoremap <C-f> :ALEFix<CR>
"nnoremap <leader>r :ALEFindReferences<CR>
"nnoremap <leader>d :ALEGoToDefinition<CR>

" Tsu
"nnoremap <Leader>i :TsuImport<CR>
"autocmd FileType typescript,typescript.tsx nnoremap <buffer> <Leader>t : <C-u>echo tsuquyomi#hint()<CR>
"nnoremap <Leader>rr :TsuRenameSymbol<CR>

" vim-fugitive & gv
nnoremap <leader>gs :G<CR>
nnoremap <leader>gd :Gvdiffsplit<CR>
nnoremap <leader>gl :GV<CR>
nnoremap <leader>gf :GV!<CR>
nmap <leader>k <Plug>(GitGutterPrevHunk)
nmap <leader>j <Plug>(GitGutterNextHunk)
nmap <leader>ghp <Plug>(GitGutterPreviewHunk)
nmap <leader>ghs <Plug>(GitGutterStageHunk)
vmap <leader>ghs <Plug>(GitGutterStageHunk)

" Python
nmap <leader>yr :w \| call VimuxRunCommandInDir("python", 1)<cr>

" CtrlSF
nmap <leader>F :CtrlSF<CR>
nmap <leader>f <Plug>CtrlSFPrompt
vmap <leader>f <Plug>CtrlSFVwordExec

" vim-test
nnoremap <leader>tn :w \| TestNearest<CR>
nnoremap <leader>tf :w \| TestFile<CR>
nnoremap <leader>tl :w \| TestLast<CR>
nnoremap <leader>tv :TestVisit<CR>

"todo
"To jump to the beginning of a C code block (while, switch, if etc), use the [{ command.
"To jump to the end of a C code block (while, switch, if etc), use the ]} command.
"The above two commands will work from anywhere inside the code block.
"To jump to the beginning of a parenthesis use the [( command.
"To jump to the end of a parenthesis use the ]) command.

" ranger
nnoremap <leader>e :Ranger <CR>

" coc------------------------------------------------------------------------
" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
"inoremap <silent><expr> <TAB>
      "\ pumvisible() ? "\<C-n>" :
      "\ <SID>check_back_space() ? "\<TAB>" :
      "\ coc#refresh()
"inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" Use tab to trigger snippets
inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-x> to trigger completion.
inoremap <silent><expr> <c-x> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" Or use `complete_info` if your vim support it, like:
" inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"

" Navigate diagnostics
nmap <silent> <leader>K <Plug>(coc-diagnostic-prev)
nmap <silent> <leader>J <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" show info (like tooltip)
nnoremap <silent> <leader>i :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction


" Remap for rename current word
nmap <leader>rr <Plug>(coc-rename)
nnoremap <silent> <leader>ri :call AleIgnore()<CR>

" Remap for format selected region
"xmap <leader>f  <Plug>(coc-format-selected)
"nmap <leader>f  <Plug>(coc-format-selected)

" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap for do codeAction of current line
nmap <silent> <leader>ac  <Plug>(coc-codeaction)
" Fix autofix problem of current line
nmap <silent> <leader>.  <Plug>(coc-fix-current)

" Create mappings for function text object, requires document symbols feature of languageserver.
"xmap if <Plug>(coc-funcobj-i)
"xmap af <Plug>(coc-funcobj-a)
"omap if <Plug>(coc-funcobj-i)
"omap af <Plug>(coc-funcobj-a)

" Use <C-d> for select selections ranges, needs server support, like: coc-tsserver, coc-python
"nmap <silent> <C-d> <Plug>(coc-range-select)
"xmap <silent> <C-d> <Plug>(coc-range-select)


" Using CocList
"" Show all diagnostics
"nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
"" Manage extensions
"nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
"" Show commands
"nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
"" Find symbol of current document
"nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
"" Search workspace symbols
"nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
"" Do default action for next item.
"nnoremap <silent> <space>j  :<C-u>CocNext<CR>
"" Do default action for previous item.
"nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
"" Resume latest coc list
"nnoremap <silent> <space>p  :<C-u>CocListResume<CR>

" Enter // to search for currently visually selected block
" Hint: enter :g/ (short for :g//p) to list all  occurences in the current file
vnoremap // y/\V<C-r>=escape(@",'/\')<CR><CR>

vmap <S-k> <Plug>SchleppIndentUp
vmap <S-j> <Plug>SchleppIndentDown

nmap <S-j> 3<C-e>
nmap <S-k> 3<C-y>
" TODO
" https://github.com/junegunn/limelight.vim
" https://github.com/junegunn/seoul256.vim
" https://github.com/junegunn/goyo.vim
"http://vimcasts.org/episodes/fugitive-vim-resolving-merge-conflicts-with-vimdiff/
" pgvy --> this will reselect and re-yank any text that is pasted in visual mode.
"https://github.com/psf/black
"http://blog.jamesnewton.com/setting-up-coc-nvim-for-ruby-development
" https://blog.carbonfive.com/2011/10/17/vim-text-objects-the-definitive-guide/
