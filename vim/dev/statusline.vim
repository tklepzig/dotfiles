highlight LcarsPrimary ctermfg=0 ctermbg=172
highlight LcarsAccent ctermfg=15 ctermbg=32
highlight LcarsGap ctermfg=NONE ctermbg=NONE
highlight LcarsLight ctermfg=0 ctermbg=179
highlight LcarsLighter ctermfg=0 ctermbg=222
highlight LcarsError ctermfg=0 ctermbg=160

function! CurrentBufferTabLine()
  let bufpath = expand("%:~:.:h")
  let bufname = expand("%:t")
  if empty(bufname)
    let bufname = "[No Name]"
  endif

  let path = (!empty(bufpath) && bufpath != ".") ? "%#LcarsLight# " . bufpath . " %#LcarsGap# " : ""
  let name = (&modified ? "%#LcarsAccent# " : "%#LcarsPrimary# ") . bufname . " %#LcarsGap# "

  return '%#LcarsPrimary# %#LcarsGap# ' . path . name . '%#LcarsPrimary#'
endfunction
set showtabline=2
set tabline=%!CurrentBufferTabLine()

function! CocStatus()
  if !exists(':CocCommand')
    return ''
  endif

  let info = get(b:, 'coc_diagnostic_info', {})
  if empty(info) 
    return ''
  endif

  let errorCount = get(info, "error", 0)
  if empty(errorCount)
    return ''
  endif

  let errorLineNr = printf(' (Line %d) ', (info.lnums)[0])
  return ' Errors: '.errorCount.errorLineNr
endfunction

function! StatusLine()
  let modeMap = {
        \ 'n': { 'name': ' NORMAL ', 'highlight': '%#LcarsPrimary#' },
        \ 'i': { 'name': ' INSERT ', 'highlight': '%#LcarsAccent#' },
        \ 'v': { 'name': ' VISUAL ', 'highlight': '%#LcarsLight#' },
        \ 'V': { 'name': ' VISUAL LINE ', 'highlight': '%#LcarsLight#' },
        \ "\<C-V>": { 'name': ' VISUAL BLOCK ', 'highlight': '%#LcarsLight#' },
        \ 'c': { 'name': ' COMMAND ', 'highlight': '%#LcarsLight#' },
        \ 't': { 'name': ' TERMINAL ', 'highlight': '%#LcarsLight#' }
        \}

  let modeRaw = mode()
  let modeFallback = { 'name': '['.modeRaw.']', 'highlight': '%#LcarsLight#' }
  let mode = get(modeMap, modeRaw, modeFallback)

  let modeName = get(mode, 'name')
  let modeHighlight = get(mode, 'highlight')
  let cocStatus = CocStatus()

  let statusline = modeHighlight.' '
  let statusline .= '%#LcarsGap# '
  let statusline .= modeHighlight.modeName
  let statusline .= '%#LcarsGap# '
  let statusline .= '%='
  let statusline .= &filetype.' '.(&readonly ? '%r ' : '')
  let statusline .= modeHighlight
  let statusline .= ' %p%% '
  let statusline .= '%#LcarsGap# '
  let statusline .= modeHighlight
  let statusline .= ' %l/%L : %v '

  if !empty(cocStatus)
    let statusline .= '%#LcarsGap# '
    let statusline .= '%#LcarsError#'.cocStatus
  endif

  return statusline
endfunction

set noruler
set noshowmode
set laststatus=2
set statusline=%!StatusLine()

