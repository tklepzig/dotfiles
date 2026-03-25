" Claude AI integration for Vim/Neovim
" Requires: claude CLI (https://claude.ai/code)
"
" Commands:
"   :Claude [prompt]       - Ask Claude (no file context)
"   :ClaudeFile [prompt]   - Ask Claude about the current file
"   :ClaudeRange [prompt]  - Ask Claude about the visual selection (use via :'<,'>ClaudeRange)
"
" Mappings:
"   <leader>ai             - Ask about current file (prompts for input)
"   <leader>ai  (visual)   - Ask about selection (prompts for input)
"   <C-b>    (insert)      - Trigger inline completion via Claude (claude CLI)
"   <C-Space> (insert)     - Trigger inline completion via Ollama (local, faster)
"   <Right>  (insert)      - Accept ghost text suggestion (both backends)

let s:buf = -1

" ── Buffer management ────────────────────────────────────────────────────────

function! s:EnsureWindow()
  if bufexists(s:buf)
    let wins = win_findbuf(s:buf)
    if empty(wins)
      execute 'botright 15split'
      execute 'buffer ' . s:buf
    else
      call win_gotoid(wins[0])
    endif
  else
    execute 'botright 15split'
    enew
    let s:buf = bufnr('%')
    setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
    setlocal filetype=markdown wrap nonumber norelativenumber
    silent file [Claude]
  endif
endfunction

function! s:WriteHeader(prompt)
  call deletebufline(s:buf, 1, '$')
  call setbufline(s:buf, 1, ['**' . a:prompt . '**', ''])
endfunction

function! s:AppendLines(lines)
  if !bufexists(s:buf)
    return
  endif
  let lnum = len(getbufline(s:buf, 1, '$'))
  call appendbufline(s:buf, lnum, a:lines)
endfunction

" ── Neovim async ─────────────────────────────────────────────────────────────

function! s:NvimOnOut(job_id, data, event)
  " Neovim splits on \n; last element is always '' or a partial line.
  " Filter trailing empty string but keep intentional blank lines.
  let lines = a:data
  if len(lines) > 0 && lines[-1] == ''
    let lines = lines[:-2]
  endif
  if !empty(lines)
    call s:AppendLines(lines)
  endif
endfunction

function! s:NvimOnErr(job_id, data, event)
  let msg = trim(join(a:data, ''))
  if !empty(msg)
    echohl WarningMsg | echom '[Claude] ' . msg | echohl None
  endif
endfunction

function! s:NvimOnExit(job_id, status, event)
  if a:status != 0
    echohl Error | echom '[Claude] Failed (exit code ' . a:status . ').' | echohl None
  else
    echom '[Claude] Done.'
  endif
endfunction

function! s:RunNvim(prompt, context)
  let job_id = jobstart(['claude', '-p', a:prompt], {
    \ 'on_stdout': function('s:NvimOnOut'),
    \ 'on_stderr': function('s:NvimOnErr'),
    \ 'on_exit':   function('s:NvimOnExit'),
    \ })
  if !empty(a:context)
    call chansend(job_id, a:context)
  endif
  call chanclose(job_id, 'stdin')
endfunction

" ── Vim 8 async ──────────────────────────────────────────────────────────────

function! s:VimOnOut(ch, data)
  call s:AppendLines(split(a:data, "\n", 1))
endfunction

function! s:VimOnErr(ch, data)
  let msg = trim(a:data)
  if !empty(msg)
    echohl WarningMsg | echom '[Claude] ' . msg | echohl None
  endif
endfunction

function! s:VimOnExit(job, status)
  if a:status != 0
    echohl Error | echom '[Claude] Failed (exit code ' . a:status . ').' | echohl None
  else
    echom '[Claude] Done.'
  endif
endfunction

function! s:RunVim(prompt, context)
  if !has('job') || !has('channel')
    echohl Error | echom '[Claude] Requires Vim 8+ with +job and +channel.' | echohl None
    return
  endif
  let job = job_start(['claude', '-p', a:prompt], {
    \ 'in_io':   'pipe',
    \ 'out_cb':  function('s:VimOnOut'),
    \ 'err_cb':  function('s:VimOnErr'),
    \ 'exit_cb': function('s:VimOnExit'),
    \ 'mode':    'nl',
    \ })
  let ch = job_getchannel(job)
  if !empty(a:context)
    call ch_sendraw(ch, a:context)
  endif
  call ch_close_in(ch)
endfunction

" ── Core function ─────────────────────────────────────────────────────────────

function! s:Run(prompt, context)
  let prompt = empty(a:prompt) ? input('[Claude] Prompt: ') : a:prompt
  if empty(prompt)
    return
  endif

  let prev_win = win_getid()
  call s:EnsureWindow()
  call s:WriteHeader(prompt)
  call win_gotoid(prev_win)

  echom '[Claude] Asking...'

  if has('nvim')
    call s:RunNvim(prompt, a:context)
  else
    call s:RunVim(prompt, a:context)
  endif
endfunction

" ── Inline completion (ghost text) ──────────────────────────────────────────

let s:ns          = nvim_create_namespace('claude_complete')
let s:complete_pos = {}
let s:pending      = ''
let s:channel      = -1
let s:stream_buf   = ''

let s:socket_path   = expand('~/.cache/claude_vim_daemon.sock')
let s:daemon_script = expand('<sfile>:p:h:h') . '/claude_daemon.py'

" ── Ghost text ────────────────────────────────────────────────────────────────

function! s:ShowSuggestion(text)
  call nvim_buf_clear_namespace(0, s:ns, 0, -1)
  if empty(a:text) | return | endif
  let s:pending = a:text
  let lines = split(a:text, "\n", 1)
  let opts = {
    \ 'virt_text':     [[lines[0], 'Comment']],
    \ 'virt_text_pos': 'inline',
    \ }
  if len(lines) > 1
    let opts.virt_lines = map(lines[1:], {_, l -> [[l, 'Comment']]})
  endif
  call nvim_buf_set_extmark(s:complete_pos.buf, s:ns, s:complete_pos.row, s:complete_pos.col, opts)
endfunction

function! s:ClearSuggestion()
  call nvim_buf_clear_namespace(0, s:ns, 0, -1)
  let s:pending    = ''
  let s:stream_buf = ''
  if s:channel >= 0
    try | call chanclose(s:channel) | catch | endtry
    let s:channel = -1
  endif
endfunction

function! s:AcceptSuggestion()
  if empty(s:pending) | return | endif
  let text = s:pending
  let row  = s:complete_pos.row
  let col  = s:complete_pos.col
  call s:ClearSuggestion()
  let lines = split(text, "\n", 1)
  call nvim_buf_set_text(s:complete_pos.buf, row, col, row, col, lines)
  let end_row = row + len(lines) - 1
  let end_col = len(lines) == 1 ? col + len(lines[0]) : len(lines[-1])
  call nvim_win_set_cursor(0, [end_row + 1, end_col])
endfunction

augroup ClaudeComplete
  autocmd!
  autocmd InsertLeave  * call s:ClearSuggestion()
  autocmd TextChangedI * call s:ClearSuggestion()
augroup END

" ── Daemon management ─────────────────────────────────────────────────────────

function! s:EnsureDaemon()
  if filereadable(s:socket_path)
    return
  endif
  call jobstart(['python3', s:daemon_script], {'detach': 1})
  for _ in range(30)
    sleep 100m
    if filereadable(s:socket_path)
      return
    endif
  endfor
  echohl Error | echom '[Claude] Daemon failed to start.' | echohl None
endfunction

" ── Streaming socket callbacks ────────────────────────────────────────────────

function! s:OnStreamData(ch, data, event)
  if a:data == ['']
    " Connection closed — finalise
    let s:channel = -1
    let text = trim(s:stream_buf)
    if !empty(text)
      call s:ShowSuggestion(text)
      echo '[Claude] <Right> to accept'
    else
      echo '[Claude] No suggestion returned.'
    endif
    redraw
    return
  endif
  " Accumulate raw chunks (Neovim splits on newlines)
  let s:stream_buf .= join(a:data, "\n")
  let text = trim(s:stream_buf)
  if !empty(text)
    call s:ShowSuggestion(text)
    redraw
  endif
endfunction

" ── Trigger ───────────────────────────────────────────────────────────────────

function! s:TriggerComplete()
  if !has('nvim')
    echohl WarningMsg | echom '[Claude] Inline completion requires Neovim.' | echohl None
    return
  endif

  call s:ClearSuggestion()
  call s:EnsureDaemon()
  if !filereadable(s:socket_path) | return | endif

  let s:complete_pos = {
    \ 'buf': bufnr('%'),
    \ 'row': line('.') - 1,
    \ 'col': col('.'),
    \ }

  " Context: up to 10 lines above + current line up to cursor.
  " col('.') in normal mode (via <C-o>) sits ON the last typed char,
  " so col('.') as length includes it, and as 0-indexed offset is after it.
  let lnum      = line('.')
  let before    = strpart(getline(lnum), 0, col('.'))
  let ctx_start = max([1, lnum - 10])
  let ctx_lines = getline(ctx_start, lnum - 1) + [before]
  let context   = join(ctx_lines, "\n")

  let prompt =
    \ "Complete the code/text below at the very end. " .
    \ "Output ONLY the raw completion with no explanation and no markdown fences:\n\n" .
    \ context

  let s:channel = sockconnect('pipe', s:socket_path, {
    \ 'on_data': function('s:OnStreamData'),
    \ })

  if s:channel < 0
    echohl Error | echom '[Claude] Could not connect to daemon.' | echohl None
    return
  endif

  call chansend(s:channel, prompt . "\n")
endfunction

" ── Ollama inline completion ──────────────────────────────────────────────────

let s:ollama_socket_path   = expand('~/.cache/ollama_vim_daemon.sock')
let s:ollama_daemon_script = expand('<sfile>:p:h:h') . '/claude_ollama_daemon.py'

" g:claude_ollama_model can be set in vimrc to override the default model
" e.g.: let g:claude_ollama_model = 'codellama:7b'

function! s:EnsureOllamaDaemon()
  if filereadable(s:ollama_socket_path)
    return
  endif
  " Start ollama serve if not already running
  if empty(system('curl -s http://localhost:11434/api/tags'))
    call jobstart(['ollama', 'serve'], {'detach': 1})
    sleep 1500m
  endif
  let env = {'OLLAMA_MODEL': get(g:, 'claude_ollama_model', 'qwen2.5-coder:1.5b')}
  call jobstart(['python3', s:ollama_daemon_script], {'detach': 1, 'env': env})
  for _ in range(30)
    sleep 100m
    if filereadable(s:ollama_socket_path)
      return
    endif
  endfor
  echohl Error | echom '[Ollama] Daemon failed to start.' | echohl None
endfunction

function! s:TriggerOllamaComplete()
  if !has('nvim')
    echohl WarningMsg | echom '[Ollama] Inline completion requires Neovim.' | echohl None
    return
  endif

  call s:ClearSuggestion()
  call s:EnsureOllamaDaemon()
  if !filereadable(s:ollama_socket_path) | return | endif

  let s:complete_pos = {
    \ 'buf': bufnr('%'),
    \ 'row': line('.') - 1,
    \ 'col': col('.'),
    \ }

  let lnum      = line('.')
  let before    = strpart(getline(lnum), 0, col('.'))
  let ctx_start = max([1, lnum - 10])
  let ctx_lines = getline(ctx_start, lnum - 1) + [before]
  let context   = join(ctx_lines, "\n")

  let prompt =
    \ "Complete the code/text below at the very end. " .
    \ "Output ONLY the raw completion with no explanation and no markdown fences:\n\n" .
    \ context

  let s:channel = sockconnect('pipe', s:ollama_socket_path, {
    \ 'on_data': function('s:OnStreamData'),
    \ })

  if s:channel < 0
    echohl Error | echom '[Ollama] Could not connect to daemon.' | echohl None
    return
  endif

  call chansend(s:channel, prompt . "\n")
endfunction

" ── Commands ──────────────────────────────────────────────────────────────────

command! -nargs=*         Claude      call <SID>Run(<q-args>, '')
command! -nargs=*         ClaudeFile  call <SID>Run(<q-args>, join(getline(1, '$'), "\n") . "\n")
command! -range -nargs=*  ClaudeRange call <SID>Run(<q-args>, join(getline(<line1>, <line2>), "\n") . "\n")

" ── Mappings ──────────────────────────────────────────────────────────────────

nnoremap <silent> <leader>ai :ClaudeFile<CR>
vnoremap <silent> <leader>ai :<C-u>ClaudeRange<CR>

inoremap <silent> <C-b>   <C-o>:call <SID>TriggerComplete()<CR>
inoremap <silent> <C-Space> <C-o>:call <SID>TriggerOllamaComplete()<CR>
inoremap <silent> <Nul>     <C-o>:call <SID>TriggerOllamaComplete()<CR>
inoremap <silent> <C-@>     <C-o>:call <SID>TriggerOllamaComplete()<CR>
inoremap <silent> <Right> <C-o>:call <SID>AcceptSuggestion()<CR>
