function! s:QueryForCurrentBuffer()
  if &filetype =~ 'typescript'
    return '^describe | ^it '
  elseif &filetype =~ 'ruby'
    if expand('%:t') =~ 'spec'
      return '^describe | ^it | ^context '
    else
      return '^module | ^class | ^def '
    endif
  endif
endfunction

function! s:JumpToLine(line)
  let lineNr = split(a:line, ' ')[0]
  execute lineNr
endfunction

function! s:BufferLines()
  return getline(1, '$')->map({index, line -> printf("\x1b[38;5;240m%4d\x1b[m %s", index + 1, line)})
endfunction

function! s:Outline()
  let query = s:QueryForCurrentBuffer()
  let options = [ '--nth=2..', '--no-sort', '--tac', '--extended', '--ansi', '-q', query]
  call fzf#run(fzf#wrap({
        \ 'source': s:BufferLines(),
        \ 'sink': function('<SID>JumpToLine'), 
        \ 'options': options,
        \ 'window': { 'width': 0.9, 'height': 0.9, 'relative': v:true }}))
endfunction

command! Outline :call <SID>Outline()

