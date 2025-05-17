let s:optionWindowWidth = ['MarkdownNavigatorWidth', 40]
let s:buffername = "markdown-navigator"

function! s:Open()
  let bufnr = bufnr(s:buffername)
  if bufnr > 0 && bufexists(bufnr)
    return
  endif

  let matches = execute('g/\v^#')



  let s:previousWinId = win_getid()
  aboveleft vnew
  execute 'file ' . s:buffername
  execute "vertical resize " . get(g:,s:optionWindowWidth[0], s:optionWindowWidth[1])

  setlocal filetype=markdownnavigator

  setlocal buftype=nofile bufhidden=wipe nowrap noswapfile
  setlocal nobuflisted nonumber norelativenumber nofoldenable
  setlocal conceallevel=2 concealcursor=nvic


  "call s:Refresh(1)

  setlocal noreadonly modifiable
  let lines = []

  for m in split(matches, '\n')
    "let lineNr = split(m, ' ')[0]
    let [_, lineNr, prefix, title; __] = matchlist(m, '\v^\s*(\d+)\s*(#+)\s*(.*)$')
    let level = len(prefix)
    echo lineNr
    echo level
    echo title

    "call add(lines, lineNr)
  endfor

  "let lines = split(matches, '\n')
  call setline(1, lines)
  setlocal readonly nomodifiable

  " TODO: Use autocmd FileType?
  "nnoremap <script> <silent> <nowait> <buffer> <CR> :call <SID>SelectBuffer("", 0)<CR>
  "nnoremap <script> <silent> <nowait> <buffer> o    :call <SID>SelectBuffer("", 0)<CR>
  "nnoremap <script> <silent> <nowait> <buffer> v    :call <SID>SelectBuffer("vertical s", 0)<CR>
  "nnoremap <script> <silent> <nowait> <buffer> s    :call <SID>SelectBuffer("s", 0)<CR>
  "nnoremap <script> <silent> <nowait> <buffer> p    :call <SID>SelectBuffer("", 1)<CR>
  "nnoremap <script> <silent> <nowait> <buffer> r    :call <SID>Refresh(1)<CR>
  "nnoremap <script> <silent> <nowait> <buffer> m    :call <SID>ToggleMode()<CR>
  "nnoremap <script> <silent> <nowait> <buffer> x    :call <SID>CloseBuffers()<CR>
  "nnoremap <script> <silent> <nowait> <buffer> z    :call <SID>ToggleZoom()<CR>
endfunction

command! MarkdownNavigatorOpen :call <SID>Open()

