" present.vim - Presentation mode for neovim
"
" Write slides in a markdown file, separated by --- on its own line.
" :Present       - start presentation
" :Present!      - exit presentation
"
" Navigation:
"   n / l / <Right>            - next slide
"   p / h / <Left>             - previous slide
"   1-9                        - jump to slide N
"   q                          - quit presentation

if !has('nvim') | finish | endif

let s:presenting = 0
let s:currentSlide = 0
let s:savedSettings = {}

function! s:FindSlideDelimiters()
  let delimiters = []
  for lineNumber in range(1, line('$'))
    if getline(lineNumber) =~# '^---\s*$'
      call add(delimiters, lineNumber)
    endif
  endfor
  return delimiters
endfunction

function! PresentFoldText()
  return ''
endfunction

function! s:ShowSlide(index)
  let delimiters = s:FindSlideDelimiters()
  let totalSlides = len(delimiters) + 1

  if a:index < 0 || a:index >= totalSlides
    return
  endif

  let s:currentSlide = a:index

  " Calculate line range for this slide
  let slideStart = a:index == 0 ? 1 : delimiters[a:index - 1] + 1
  let slideEnd = a:index < len(delimiters) ? delimiters[a:index] - 1 : line('$')

  " Clear existing folds, then fold everything outside the current slide
  normal! zE

  if slideStart > 1
    execute '1,' . (slideStart - 1) . 'fold'
  endif

  if slideEnd < line('$')
    execute (slideEnd + 1) . ',' . line('$') . 'fold'
  endif

  " Position slide content at the top of the screen
  execute 'normal! ' . slideStart . 'Gzt'

  redraw
  echo 'Slide ' . (a:index + 1) . '/' . totalSlides
endfunction

function! s:NextSlide()
  let totalSlides = len(s:FindSlideDelimiters()) + 1
  if s:currentSlide + 1 < totalSlides
    call s:ShowSlide(s:currentSlide + 1)
  endif
endfunction

function! s:PrevSlide()
  if s:currentSlide > 0
    call s:ShowSlide(s:currentSlide - 1)
  endif
endfunction

function! s:JumpToSlide(number)
  let totalSlides = len(s:FindSlideDelimiters()) + 1
  let index = a:number - 1
  if index >= 0 && index < totalSlides
    call s:ShowSlide(index)
  endif
endfunction

function! s:StartPresent()
  if s:presenting
    return
  endif

  let s:presenting = 1
  let s:currentSlide = 0

  let s:savedSettings = {
        \ 'laststatus': &laststatus,
        \ 'showmode': &showmode,
        \ 'showcmd': &showcmd,
        \ 'ruler': &ruler,
        \ 'number': &number,
        \ 'relativenumber': &relativenumber,
        \ 'cursorline': &cursorline,
        \ 'scrolloff': &scrolloff,
        \ 'wrap': &wrap,
        \ 'linebreak': &linebreak,
        \ 'signcolumn': &signcolumn,
        \ 'foldenable': &foldenable,
        \ 'foldmethod': &foldmethod,
        \ 'foldtext': &foldtext,
        \ 'foldcolumn': &foldcolumn,
        \ 'fillchars': &fillchars,
        \ 'colorscheme': get(g:, 'colors_name', 'codedark'),
        \ 'hlFolded': nvim_get_hl(0, #{name: 'Folded'}),
        \ }

  set laststatus=0
  set noshowmode
  set noshowcmd
  set noruler
  set nonumber
  set norelativenumber
  set nocursorline
  set scrolloff=0
  set wrap linebreak
  set signcolumn=no

  " Fold-based slide isolation: hide everything outside the current slide
  set foldenable
  set foldmethod=manual
  set foldtext=PresentFoldText()
  set foldcolumn=0
  let &fillchars .= ',fold: ,eob: '
  highlight Folded NONE

  colorscheme seoul256
  Goyo 80

  " Re-apply after Goyo (colorscheme may reset highlights)
  highlight Folded NONE

  " Apply heading colors from current theme
  execute 'highlight htmlH1 cterm=bold ctermfg=' . g:accentText
  execute 'highlight htmlH2 cterm=bold ctermfg=' . g:primaryText
  execute 'highlight htmlH3 ctermfg=' . g:secondaryText
  execute 'highlight htmlH4 ctermfg=' . g:secondaryText
  execute 'highlight htmlH5 ctermfg=' . g:secondaryText
  execute 'highlight htmlH6 ctermfg=' . g:secondaryText

  " Slide navigation
  nnoremap <buffer> <silent> n :call <SID>NextSlide()<CR>
  nnoremap <buffer> <silent> p :call <SID>PrevSlide()<CR>
  nnoremap <buffer> <silent> l :call <SID>NextSlide()<CR>
  nnoremap <buffer> <silent> h :call <SID>PrevSlide()<CR>
  nnoremap <buffer> <silent> <Right> :call <SID>NextSlide()<CR>
  nnoremap <buffer> <silent> <Left> :call <SID>PrevSlide()<CR>
  nnoremap <buffer> <silent> q :Present!<CR>

  " Direct slide jump
  nnoremap <buffer> <silent> 1 :call <SID>JumpToSlide(1)<CR>
  nnoremap <buffer> <silent> 2 :call <SID>JumpToSlide(2)<CR>
  nnoremap <buffer> <silent> 3 :call <SID>JumpToSlide(3)<CR>
  nnoremap <buffer> <silent> 4 :call <SID>JumpToSlide(4)<CR>
  nnoremap <buffer> <silent> 5 :call <SID>JumpToSlide(5)<CR>
  nnoremap <buffer> <silent> 6 :call <SID>JumpToSlide(6)<CR>
  nnoremap <buffer> <silent> 7 :call <SID>JumpToSlide(7)<CR>
  nnoremap <buffer> <silent> 8 :call <SID>JumpToSlide(8)<CR>
  nnoremap <buffer> <silent> 9 :call <SID>JumpToSlide(9)<CR>

  " Wrapped-line navigation
  nnoremap <buffer> <silent> j gj
  nnoremap <buffer> <silent> k gk

  call s:ShowSlide(0)
endfunction

function! s:StopPresent()
  if !s:presenting
    return
  endif

  let s:presenting = 0

  " Remove buffer-local mappings
  for key in ['n', 'p', 'l', 'h', '<Right>', '<Left>', 'q',
        \ '1', '2', '3', '4', '5', '6', '7', '8', '9', 'j', 'k']
    execute 'silent! nunmap <buffer> ' . key
  endfor

  " Remove folds
  normal! zE

  Goyo!

  execute 'colorscheme ' . s:savedSettings.colorscheme
  source $HOME/.dotfiles/vim/vim/highlight-overrides.vim
  call nvim_set_hl(0, 'Folded', s:savedSettings.hlFolded)

  let &laststatus = s:savedSettings.laststatus
  let &showmode = s:savedSettings.showmode
  let &showcmd = s:savedSettings.showcmd
  let &ruler = s:savedSettings.ruler
  let &number = s:savedSettings.number
  let &relativenumber = s:savedSettings.relativenumber
  let &cursorline = s:savedSettings.cursorline
  let &scrolloff = s:savedSettings.scrolloff
  let &wrap = s:savedSettings.wrap
  let &linebreak = s:savedSettings.linebreak
  let &signcolumn = s:savedSettings.signcolumn
  let &foldenable = s:savedSettings.foldenable
  let &foldmethod = s:savedSettings.foldmethod
  let &foldtext = s:savedSettings.foldtext
  let &foldcolumn = s:savedSettings.foldcolumn
  let &fillchars = s:savedSettings.fillchars
endfunction

command! -bang Present if <bang>0 | call <SID>StopPresent() | else | call <SID>StartPresent() | endif
