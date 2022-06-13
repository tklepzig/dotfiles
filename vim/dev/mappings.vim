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
nnoremap <Leader>ob :Buffers<CR>
nnoremap <Leader>ol :Lines<CR>
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

"" Go to last active tab
"au TabLeave * let g:lasttab = tabpagenr()
"nnoremap <silent> <leader><Tab> :exe "tabn ".g:lasttab<cr>
"vnoremap <silent> <leader><Tab> :exe "tabn ".g:lasttab<cr>


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

" CtrlSF
nmap <leader>F :CtrlSF<CR>
nmap <leader>f <Plug>CtrlSFPrompt
vmap <leader>f <Plug>CtrlSFVwordExec

" ranger
nnoremap <leader>e :Ranger <CR>

" Jump to next/prev spell check issue
nnoremap <leader>c ]s
nnoremap <leader>C [s

nnoremap gJ :call GoToNextIndent(1)<CR>
nnoremap gK :call GoToNextIndent(-1)<CR>

" Coc
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

