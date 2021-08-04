highlight LcarsPrimary ctermfg=0 ctermbg=172
highlight LcarsAccent ctermfg=15 ctermbg=32
highlight LcarsGap ctermfg=NONE ctermbg=NONE
highlight LcarsLight ctermfg=0 ctermbg=179
highlight LcarsLighter ctermfg=0 ctermbg=222
highlight LcarsError ctermfg=255 ctermbg=124
highlight LcarsInactive ctermfg=255 ctermbg=237

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
	let isActive = g:statusline_winid == win_getid()

  if (!isActive)
    let bufnr = get(getwininfo(g:statusline_winid)[0], 'bufnr')
    let bufFiletype = getbufvar(bufnr, '&filetype')
    let bufReadonly = getbufvar(bufnr, '&readonly')

    let bufpath = fnamemodify(bufname(bufnr), ":~:.:h")
    let bufname = fnamemodify(bufname(bufnr), ":t")
    let inactiveLine = '%#LcarsInactive# '
    let inactiveLine .= '%#LcarsGap# '
    let inactiveLine .= '%#LcarsInactive# '
    let inactiveLine .= bufpath.' '
    let inactiveLine .= '%#LcarsGap# '
    let inactiveLine .= '%#LcarsInactive# '
    let inactiveLine .= bufname.' '
    let inactiveLine .= '%#LcarsGap# '
    let inactiveLine .= '%='
    let inactiveLine .= '        '
    let inactiveLine .= bufFiletype.' '.(bufReadonly ? '%r ' : '')
    let inactiveLine .= '%#LcarsInactive#'
    let inactiveLine .= ' %p%% '
    let inactiveLine .= '%#LcarsGap# '
    let inactiveLine .= '%#LcarsInactive#'
    let inactiveLine .= ' %l/%L : %v '
    return inactiveLine
  endif

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

  let line = modeHighlight.' '
  let line .= '%#LcarsGap# '
  let line .= modeHighlight.modeName
  let line .= '%#LcarsGap# '
  let line .= '%='
  let line .= &filetype.' '.(&readonly ? '%r ' : '')
  let line .= modeHighlight
  let line .= ' %p%% '
  let line .= '%#LcarsGap# '
  let line .= modeHighlight
  let line .= ' %l/%L : %v '

  if !empty(cocStatus)
    let line .= '%#LcarsGap# '
    let line .= '%#LcarsError#'.cocStatus
  endif

  return line
endfunction

set noruler
set noshowmode
set laststatus=2
set statusline=%!StatusLine()
