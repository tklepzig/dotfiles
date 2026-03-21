let mapleader = "\<space>"

function! NERDTreeSmartToggle()
  if @% == ""
    NERDTreeToggle
  elseif (exists("t:NERDTreeBufName") && bufwinnr(t:NERDTreeBufName) != -1)
    NERDTreeClose
  else
    NERDTreeFind
  endif
endfun

nnoremap <silent> <leader>n :call NERDTreeSmartToggle()<CR>

nnoremap <Leader>/ :History/<CR>
nnoremap <Leader>: :History:<CR>
nnoremap <Leader>o :Outline<CR>
nnoremap <Leader>G :GFiles?<CR>
nnoremap <Leader>b :Buffers<CR>
nnoremap <Leader>B :BLines<CR>
nnoremap <Leader>p :GFiles<CR>
nnoremap <Leader>P :History<CR>
nnoremap <Leader>; :Commands<CR>

nnoremap <leader>, :VimuxPromptCommand<cr>
nnoremap <leader>vp :VimuxPromptCommand<cr>
nnoremap <leader>vl :VimuxRunLastCommand<cr>
nnoremap <leader>vi :VimuxInspectRunner<cr>
nnoremap <leader>vz :VimuxZoomRunner<cr>
nnoremap <leader>vZ :VimuxZoomRunner<cr>:VimuxInspectRunner<cr>

nnoremap <silent> <leader>e :call OpenRangerForCurrentFile()<CR>

nnoremap <leader><Tab> :BufferNavigatorToggle<cr>

" --- tab handling ---
" built-in mappings:
"   Go to next tab: gt
"   Go to previous tab: gT
"   Go to last accessed tab: g<Tab>
"
" additional ones:
"
" not yet clear which mapping works best in daily usage
nnoremap <silent> <leader>wt :$tab split<cr>
nnoremap <silent> gn :$tab split<cr>

nnoremap <silent> <Tab> :tabNext<cr>

nnoremap <silent> <leader>wQ :tabclose<cr>
nnoremap <silent> gc :tabclose<cr>

" not yet clear which mapping works best in daily usage
nnoremap <leader>w1 1gt
nnoremap <leader>w2 2gt
nnoremap <leader>w3 3gt
nnoremap <leader>w4 4gt
nnoremap <leader>w5 5gt
nnoremap <leader>w6 6gt
nnoremap <leader>w7 7gt
nnoremap <leader>w8 8gt
nnoremap <leader>w9 9gt
nnoremap g1 1gt
nnoremap g2 2gt
nnoremap g3 3gt
nnoremap g4 4gt
nnoremap g5 5gt
nnoremap g6 6gt
nnoremap g7 7gt
nnoremap g8 8gt
nnoremap g9 9gt

" diff buffers directly in place
nnoremap <expr> <leader>wd &diff? ':windo diffoff<CR>' : ':windo diffthis<CR>'

nmap <expr> <S-Left> &diff? '<Plug>(MergetoolDiffExchangeLeft)' : '<S-Left>'

" vim-fugitive & gv
nnoremap <leader>gs :G<CR>
nnoremap <leader>gd :Gvdiffsplit<CR>
nnoremap <leader>gb :execute 'Gvdiffsplit! ' . $DOTFILES_GIT_DEFAULT_BRANCH . ' \| wincmd p'<CR>
nnoremap <leader>gl :GV<CR>
nnoremap <leader>gf :GV!<CR>
nmap <leader>k <Plug>(GitGutterPrevHunk)
nmap <leader>j <Plug>(GitGutterNextHunk)
nmap <leader>ghp <Plug>(GitGutterPreviewHunk)
nmap <leader>ghs <Plug>(GitGutterStageHunk)
vmap <leader>ghs <Plug>(GitGutterStageHunk)

" CtrlSF
nmap <leader>F :CtrlSF<CR>
nmap <leader>f <Plug>CtrlSFPrompt
vmap <leader>f <Plug>CtrlSFVwordExec

" Jump to next/prev spell check issue
nnoremap <silent> gs ]s
nnoremap <silent> gS [s

nnoremap <silent> zj :call JumpToSameIndent('down', 0)<CR>
vnoremap <silent> zj :call JumpToSameIndent('down', 1)<CR>
nnoremap <silent> zk :call JumpToSameIndent('up', 0)<CR>
vnoremap <silent> zk :call JumpToSameIndent('up', 1)<CR>

" Jump to closest opening bracket, ignoring any sibling objects
" e.g. with gp{ in json files with long objects to jump to the start of current object the cursor is in
nnoremap <silent> gp{ _ya{
nnoremap <silent> gp[ _ya[
nnoremap <silent> gp( _ya(

augroup aichat
    autocmd!
    
    " edit text with a custom prompt
    "xnoremap <leader>s :AIEdit fix grammar and spelling<CR>
    "nnoremap <leader>s :AIEdit fix grammar and spelling<CR>
    
    " redo last AI command
    "nnoremap <leader>r :AIRedo<CR>

    autocmd FileType aichat xnoremap <buffer> <nowait> <leader>c :AIChat<cr>
    autocmd FileType aichat nnoremap <buffer> <nowait> <leader>c :AIChat<cr>

    autocmd FileType aichat nnoremap <buffer> <nowait> <leader>m :set buftype= \| 0file \| QuickMemo local aichat<CR>
augroup END

nmap <leader>gr <Plug>(MergetoolToggle)
nmap <leader>gmt <Plug>(MergetoolToggle)
nmap <leader>gmr :MergetoolPreferRemote<cr>
nmap <leader>gml :MergetoolPreferLocal<cr>
nmap <leader>gm2 :MergetoolSetLayout mr<cr>
nmap <leader>gm3 :MergetoolSetLayout b,mr<cr>
nmap <expr> <S-Left> &diff? '<Plug>(MergetoolDiffExchangeLeft)' : '<S-Left>'
nmap <expr> <S-Right> &diff? '<Plug>(MergetoolDiffExchangeRight)' : '<S-Right>'
nmap <expr> <S-Down> &diff? '<Plug>(MergetoolDiffExchangeDown)' : '<S-Down>'
nmap <expr> <S-Up> &diff? '<Plug>(MergetoolDiffExchangeUp)' : '<S-Up>'

nnoremap cx <Plug>(conflict-marker-next-hunk)
nnoremap cX <Plug>(conflict-marker-prev-hunk)

" vim-test
nnoremap <leader>tn :w \| TestNearest<CR>
nnoremap <leader>tf :w \| TestFile<CR>
nnoremap <leader>tl :w \| TestLast<CR>
nnoremap <leader>tv :TestVisit<CR>
nnoremap <leader>tz :VimuxZoomRunner<CR>

" TODO
"http://vimcasts.org/episodes/fugitive-vim-resolving-merge-conflicts-with-vimdiff/
" pgvy --> this will reselect and re-yank any text that is pasted in visual mode.
"https://github.com/psf/black
"http://blog.jamesnewton.com/setting-up-coc-nvim-for-ruby-development
" https://blog.carbonfive.com/2011/10/17/vim-text-objects-the-definitive-guide/

nnoremap <silent> <leader>dr :%SourceSelection<cr>
vnoremap <silent> <leader>dr :SourceSelection<cr>
nnoremap <silent> <leader>ds :call ToggleStatusline()<cr>

augroup vimspec
    autocmd!
    autocmd FileType vimspec nnoremap <buffer> <nowait> <leader>t :Themis<cr>
augroup END


augroup ruby
    autocmd!
    autocmd FileType ruby nnoremap <buffer> <leader>2 :AlternateSafe<cr>
augroup END

" LSP

" Navigate diagnostics (mirrors CoC <leader>K / <leader>J)
nmap <silent> <leader>K <cmd>lua vim.diagnostic.goto_prev()<CR>
nmap <silent> <leader>J <cmd>lua vim.diagnostic.goto_next()<CR>

" Go to definition / type / implementation / references (same keys as CoC)
nmap <silent> gd <cmd>lua vim.lsp.buf.definition()<CR>
nmap <silent> gy <cmd>lua vim.lsp.buf.type_definition()<CR>
nmap <silent> gi <cmd>lua vim.lsp.buf.implementation()<CR>
nmap <silent> gr <cmd>lua vim.lsp.buf.references()<CR>

" Show hover documentation (mirrors CoC <leader>i)
nnoremap <silent> <leader>i <cmd>lua
      \ if vim.tbl_contains({'vim', 'help'}, vim.bo.filetype) then
      \   vim.cmd('h ' .. vim.fn.expand('<cword>'))
      \ else
      \   vim.lsp.buf.hover()
      \ end<CR>

" Rename symbol (mirrors CoC <leader>rr)
nmap <leader>rr <cmd>lua vim.lsp.buf.rename()<CR>

" Code action for selected region or current line (mirrors CoC <leader>a / <leader>ac)
xmap <leader>a  <cmd>lua vim.lsp.buf.code_action()<CR>
nmap <leader>a  <cmd>lua vim.lsp.buf.code_action()<CR>
nmap <silent> <leader>ac <cmd>lua vim.lsp.buf.code_action()<CR>

" Apply preferred / first quick-fix (mirrors CoC <leader>.)
nmap <silent> <leader>. <cmd>lua vim.lsp.buf.code_action({ apply = true, filter = function(a) return a.isPreferred end })<CR>
