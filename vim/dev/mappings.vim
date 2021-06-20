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
