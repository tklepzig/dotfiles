let s:optionAutoClose = ['MarkdownNavigatorAutoClose', 1]
let s:optionMapKeys = ['MarkdownNavigatorMapKeys', 1]
let s:optionWindowWidth = ['MarkdownNavigatorWidth', 40]

let s:bufferName = "markdown-navigator"
let s:headingLineMapping = {}

let s:documentBufferNr = -1
let s:documentWinId = -1
let s:navigatorWinId = -1

function! s:BuildHeadings()
  let headings = []

  call win_gotoid(s:documentWinId)
  let view = winsaveview()

  let matches = execute('g/\v^#')
  for matchLine in split(matches, '\n')
    let [_, lineNr, level, title; _] = matchlist(matchLine, '\v^\s*(\d+)\s*(#+)\s*(.*)$')
    call add(headings, [str2nr(lineNr), len(level), title])
  endfor

  call winrestview(view)
  call win_gotoid(s:navigatorWinId)

  return headings
endfunction

function! s:HeadingLineNrFromCurrentLine()
  let lineNr = line(".")
  if has_key(s:headingLineMapping, lineNr)
    return s:headingLineMapping[lineNr]
  endif
  return 0
endfunction

function! s:SelectHeading(mode)
  let lineNr = s:HeadingLineNrFromCurrentLine()
  if lineNr == 0
    return
  endif

  if a:mode == "preview"
    call win_execute(s:documentWinId, 'silent buffer ' . s:documentBufferNr)
    call win_execute(s:documentWinId, 'silent normal! ' . lineNr . 'Gzz')
    return
  endif

  call win_gotoid(s:documentWinId)
  execute 'silent buffer ' . s:documentBufferNr
  call setpos(".", [s:documentBufferNr, lineNr, 1])
  normal zz

  if a:mode == "close" && get(g:, s:optionAutoClose[0], s:optionAutoClose[1])
    call s:Close()
  endif
endfunction

function! s:PrintLines(documentLineNr)
  setlocal noreadonly modifiable

  let selectedLineNr = line(".")

  let curLine = 1
  for [lineNr, level, title] in s:BuildHeadings()
    call setline(curLine, repeat('  ', level - 1) . title)
    let s:headingLineMapping[curLine] = lineNr

    if a:documentLineNr > 0 && a:documentLineNr >= lineNr
      let selectedLineNr = curLine
    endif

    let curLine += 1
  endfor

  setlocal readonly nomodifiable

  call setpos(".", [0, selectedLineNr, 1])
endfunction

function! s:Open()
  let bufnr = bufnr(s:bufferName)
  if bufnr > 0 && bufexists(bufnr)
    return
  endif

  let documentLineNr = line(".")
  let s:documentBufferNr = bufnr("%")
  let s:documentWinId = win_getid()

  aboveleft vnew
  let s:navigatorWinId = win_getid()
  execute 'silent file ' . s:bufferName
  execute "vertical resize " . get(g:,s:optionWindowWidth[0], s:optionWindowWidth[1])

  setlocal filetype=markdownnavigator

  """ put into ftplugin file
  setlocal buftype=nofile bufhidden=wipe nowrap noswapfile
  setlocal nobuflisted nonumber norelativenumber nofoldenable
  setlocal conceallevel=0
  "setlocal conceallevel=2 concealcursor=nvic
  """
  
  """ put into syntax file
  syntax match MarkdownNavigatorH1 "^[^ ].*"
  syntax match MarkdownNavigatorH2 "^\s\{2\}[^ ].*"
  syntax match MarkdownNavigatorH3 "^\s\{4\}[^ ].*"
  syntax match MarkdownNavigatorH4 "^\s\{6\}[^ ].*"
  syntax match MarkdownNavigatorH5 "^\s\{8\}[^ ].*"
  syntax match MarkdownNavigatorH6 "^\s\{10\}[^ ].*"
  """

  call s:PrintLines(documentLineNr)
endfunction

function! s:Close()
  let bufnr = bufnr(s:bufferName)
  if bufnr > 0 && bufexists(bufnr)
    if s:documentWinId > 0
      call win_gotoid(s:documentWinId)
    endif
    execute 'bwipeout! ' . bufnr
  endif
endfunction

function! s:Toggle()
  let bufnr = bufnr(s:bufferName)
  if bufnr > 0 && bufexists(bufnr)
    if win_getid() != s:navigatorWinId
      " The navigator window is the active window, switch to it instead of
      " closing it
      call win_gotoid(s:navigatorWinId)
    else
      call s:Close()
    endif
  else
    call s:Open()
  endif
endfunction

function! s:ToggleZoom()
  let winWidth = get(g:,s:optionWindowWidth[0], s:optionWindowWidth[1])

  if winwidth(0) > winWidth
  execute "vertical resize " . winWidth
  else
    vertical resize
  endif
endfunction

function! s:ChangeRootHeading()
  let currentLineNr = line(".")
  let newRootHeadingIndent = indent(currentLineNr)

  setlocal noreadonly modifiable
  let deletedLinesAboveCount = currentLineNr - 1 
 
  " Delete all lines above
  call deletebufline("%", 1, deletedLinesAboveCount)

  " Delete all lines below which are not children of the new root heading
  " and update the heading line mapping by shifting its entries via
  " re-assignment
  for lineNr in range(1, line("$"))
    let s:headingLineMapping[lineNr] = s:headingLineMapping[lineNr + deletedLinesAboveCount]

    if lineNr > 1 && indent(lineNr) <= newRootHeadingIndent
      call deletebufline("%", lineNr, "$")
      break
    endif
  endfor
  setlocal readonly nomodifiable
endfunction

command! MarkdownNavigatorOpen :call <SID>Open()
command! MarkdownNavigatorClose :call <SID>Close()
command! MarkdownNavigatorToggle :call <SID>Toggle()

" move all but the leader-t mapping into the ftplugin file?
augroup MarkdownNavigator
  autocmd!
  autocmd FileType markdownnavigator noremap <script> <silent> <nowait> <buffer> <CR> :call <SID>SelectHeading("close")<CR>
  autocmd FileType markdownnavigator noremap <script> <silent> <nowait> <buffer> o    :call <SID>SelectHeading("switch")<CR>
  autocmd FileType markdownnavigator noremap <script> <silent> <nowait> <buffer> p    :call <SID>SelectHeading("preview")<CR>
  autocmd FileType markdownnavigator noremap <script> <silent> <nowait> <buffer> q    :call <SID>Close()<CR>
  autocmd FileType markdownnavigator noremap <script> <silent> <nowait> <buffer> z    :call <SID>ToggleZoom()<CR>
  autocmd FileType markdownnavigator noremap <script> <silent> <nowait> <buffer> r    :call <SID>PrintLines(0)<CR>
  autocmd FileType markdownnavigator noremap <script> <silent> <nowait> <buffer> c    :call <SID>ChangeRootHeading()<CR>

  if get(g:, s:optionMapKeys[0], s:optionMapKeys[1])
    autocmd FileType markdown,markdownnavigator nnoremap <script> <silent> <nowait> <buffer> <leader>t :MarkdownNavigatorToggle<CR>
  endif
augroup END


