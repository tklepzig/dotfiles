" Git file history navigation
" Allows stepping back/forward through commits that touched the current file.
" Mappings:
"   <leader>gj / <leader>gk – back / forward scoped to whole file
"   <leader>gJ / <leader>gK – back / forward scoped to current line

let s:history_commits = []   " ordered newest-first (git log order)
let s:history_index  = -1    " -1 = current working copy
let s:history_file   = ''    " absolute path of the tracked file
let s:history_root   = ''    " git repo root
let s:history_rel    = ''    " path relative to repo root
let s:history_line   = -1    " cursor line when the session started (-1 = file mode)
let s:history_mode   = ''    " 'line' or 'file'
let s:line_context   = 5     " lines above/below cursor for line-mode range

function! s:LoadHistory(filepath, mode, line) abort
  let l:root = trim(system('git -C ' . shellescape(fnamemodify(a:filepath, ':h'))
        \ . ' rev-parse --show-toplevel 2>/dev/null'))
  if v:shell_error
    echo 'git-history: not inside a git repository'
    return 0
  endif

  let l:rel = a:filepath[len(l:root) + 1:]

  if a:mode ==# 'line'
    " git log -L emits full patches; filter output down to bare commit hashes
    let l:from = max([1, a:line - s:line_context])
    let l:to   = a:line + s:line_context
    let l:log_output = systemlist('git -C ' . shellescape(l:root)
          \ . ' log -L ' . l:from . ',' . l:to . ':' . shellescape(l:rel)
          \ . ' --format=%H')
    let l:commits = filter(copy(l:log_output), 'v:val =~# ''^[0-9a-f]\{40\}$''')
  else
    let l:commits = systemlist('git -C ' . shellescape(l:root)
          \ . ' log --follow --format=%H -- ' . shellescape(l:rel))
  endif

  if empty(l:commits)
    let l:scope = a:mode ==# 'line' ? 'line ' . a:line : 'file'
    echo 'git-history: no commits found for ' . l:scope
    return 0
  endif

  let s:history_commits = l:commits
  let s:history_index   = -1
  let s:history_file    = a:filepath
  let s:history_root    = l:root
  let s:history_rel     = l:rel
  let s:history_line    = a:line
  let s:history_mode    = a:mode
  return 1
endfunction

function! s:CommitLabel(index) abort
  let l:hash    = s:history_commits[a:index]
  let l:short   = l:hash[:6]
  let l:subject = trim(system('git -C ' . shellescape(s:history_root)
        \ . ' log --format=%s -1 ' . l:hash))
  let l:total   = len(s:history_commits)
  let l:scope   = s:history_mode ==# 'line'
        \ ? printf(' (lines %d-%d)', max([1, s:history_line - s:line_context]), s:history_line + s:line_context)
        \ : ' (file)'
  return printf('[%d/%d] %s  %s%s', a:index + 1, l:total, l:short, l:subject, l:scope)
endfunction

" Navigate within the active session.
" a:mode is 'line' or 'file' and determines which history scope to use.
function! s:GitHistoryNavigate(direction, mode, ...) abort
  let l:count      = max([1, get(a:, 1, 1)])
  let l:in_history = bufname('%') =~# '^fugitive://'

  if l:in_history && !empty(s:history_commits) && s:history_mode ==# a:mode
    " Reuse existing session – mode matches
  else
    " Load (or reload) for the requested mode
    if l:in_history
      let l:filepath = s:history_file
      let l:line     = s:history_line
    else
      let l:filepath = expand('%:p')
      if empty(l:filepath) || !filereadable(l:filepath)
        echo 'git-history: buffer has no readable file'
        return
      endif
      let l:line = line('.')
    endif
    " For line mode: also reload when the cursor moved to a different line
    if empty(s:history_commits)
          \ || l:filepath !=# s:history_file
          \ || a:mode !=# s:history_mode
          \ || (a:mode ==# 'line' && !l:in_history && l:line != s:history_line)
      if !s:LoadHistory(l:filepath, a:mode, l:line)
        return
      endif
    endif
  endif

  let l:saved_pos = getpos('.')

  if a:direction ==# 'back'
    let l:new_index = min([s:history_index + l:count, len(s:history_commits) - 1])
    if l:new_index == s:history_index
      echo 'git-history: already at oldest commit'
      return
    endif
    let s:history_index = l:new_index
    execute 'Gedit ' . s:history_commits[s:history_index] . ':' . s:history_rel
    call setpos('.', l:saved_pos)
    echo 'git-history: ' . s:CommitLabel(s:history_index)

  else
    if s:history_index <= -1
      echo 'git-history: already at current working copy'
      return
    endif
    let l:new_index = max([s:history_index - l:count, -1])
    let s:history_index = l:new_index

    if s:history_index == -1
      execute 'edit ' . fnameescape(s:history_file)
      call setpos('.', l:saved_pos)
      let l:scope = s:history_mode ==# 'line'
            \ ? printf(' (lines %d-%d)', max([1, s:history_line - s:line_context]), s:history_line + s:line_context)
            \ : ' (file)'
      echo 'git-history: back to working copy' . l:scope
    else
      execute 'Gedit ' . s:history_commits[s:history_index] . ':' . s:history_rel
      call setpos('.', l:saved_pos)
      echo 'git-history: ' . s:CommitLabel(s:history_index)
    endif
  endif
endfunction

nnoremap <silent> <leader>gj :<C-u>call <SID>GitHistoryNavigate('back',    'file', v:count1)<CR>
nnoremap <silent> <leader>gk :<C-u>call <SID>GitHistoryNavigate('forward', 'file', v:count1)<CR>
nnoremap <silent> <leader>gJ :<C-u>call <SID>GitHistoryNavigate('back',    'line', v:count1)<CR>
nnoremap <silent> <leader>gK :<C-u>call <SID>GitHistoryNavigate('forward', 'line', v:count1)<CR>
