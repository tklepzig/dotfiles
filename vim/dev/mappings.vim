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
nnoremap <Leader>o :Files<CR>
nnoremap <Leader>of :Files<CR>
nnoremap <Leader>og :GFiles?<CR>
nnoremap <Leader>ol :Lines<CR>
nnoremap <Leader>b :Buffers<CR>
nnoremap <Leader>p :GFiles<CR>
nnoremap <Leader>P :History<CR>
nnoremap <Leader>; :Commands<CR>

nnoremap <leader>, :VimuxPromptCommand<cr>
nnoremap <leader>vp :VimuxPromptCommand<cr>
nnoremap <leader>vl :VimuxRunLastCommand<cr>
nnoremap <leader>vi :VimuxInspectRunner<cr>
nnoremap <leader>vz :VimuxZoomRunner<cr>
nnoremap <leader>vZ :VimuxZoomRunner<cr>:VimuxInspectRunner<cr>

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

    autocmd FileType aichat nnoremap <buffer> <nowait> <leader>m :set buftype= \| 0file \| QuickMemo aichat<CR>
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

" Coc

" Use <down> and <up> to navigate completion list:
inoremap <silent><expr> <Down>
      \ coc#pum#visible() ? coc#pum#next(1) : "\<Down>"
inoremap <expr><Up> coc#pum#visible() ? coc#pum#prev(1) : "\<Up>"

" Map <tab> for trigger completion, completion confirm, snippet expand and jump
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ?
      \ "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:coc_snippet_next = '<tab>'

" Use <CR> to confirm completion
" No abbreviations with carriage returns in it are possible anymore
"inoremap <expr> <cr> coc#pum#visible() ? coc#_select_confirm() : "\<CR>"

" Use <c-x> to trigger completion
inoremap <silent><expr> <c-x> coc#refresh()


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

