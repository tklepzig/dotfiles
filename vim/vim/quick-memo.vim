function! s:CommitAndPush(filepath)
  let gitCmd = 'git -C "'. fnamemodify(a:filepath, ":p:h") . '"'
  call system(gitCmd . ' add "' . a:filepath . '" && '. gitCmd . ' commit -m "Update ' . fnamemodify(a:filepath, ":t") . '" && '. gitCmd . ' push')
  if v:shell_error
    echohl Error | echo "An error occured while updating the quick memo repo."  | echohl None
  endif
endfunction

function! s:IsGitRepo(dir)
  return system('git -C ' . a:dir . ' rev-parse --is-inside-work-tree 2> /dev/null')->substitute('\n', '', 'g') == 'true'
endfunction

function! s:QuickMemo(mode = "local", ext = "md")
  let path = get(g:,"quick_memo_path", $HOME . '/.dotfiles-local/quick-memo')
  let isGitRepo = s:IsGitRepo(path)

  if !empty(expand("%"))
    let fileIsQuickMemo = expand("%:p:h") == path
    if !fileIsQuickMemo
      echohl Error | echo "Not a quick memo" | echohl None
      return
    endif
    w
    if a:mode == "git" && isGitRepo
      call s:CommitAndPush(expand("%:p"))
    endif
    return
  endif

  if !isdirectory(path)
    call mkdir(path)
  endif

  let firstChars = ''
  let firstLine = getline(1)

  if !empty(firstLine)
    let firstCharsSafe = substitute(firstLine[:29], '/', '-', 'g')
    let firstCharsSafe = substitute(firstCharsSafe, '^\#*\s*', '', 'g')

    " escape # bc of special meaning of #
    " (alternate filename when passing it to w)
    let firstCharsSafe = substitute(firstCharsSafe, '\#', '\\#', 'g')
    let firstChars = '--' . firstCharsSafe
  endif

  let filename = strftime('%Y-%m-%d-%H:%M:%S') . firstChars . '.' . a:ext
  execute('w ' . path . '/' . filename)

  if a:ext == "md"
    set filetype=markdown
  endif

  if a:mode == "git" && isGitRepo
      call s:CommitAndPush(path . '/' . filename)
  endif

endfunction
command! -nargs=* QuickMemo :call <SID>QuickMemo(<f-args>)

