local OVERVIEW_PROMPT = [[
Give me an orientation briefing on `%s` in this repository.

Read it, then look around the repo and tell me:
- What this file is for, in a sentence or two.
- How it is wired in: what imports it, what it reaches for, who calls it.
- The non-obvious parts — invariants, surprising decisions, anything that would
  bite someone changing it.
- Anything stale, dead, or inconsistent with how the rest of the repo does it.

Do not list the symbols or restate the structure; an editor outline already
shows that. No preamble and no account of your process. Markdown, under 400
words, cite locations as `path:line`.
]]

local PROMPT_POLL_INTERVAL_MS = 250
local PROMPT_TIMEOUT_MS = 20000

local function notify(message, level)
  vim.notify("Claude: " .. message, level or vim.log.levels.INFO)
end

local function repo_root_for(filepath)
  local dir = vim.fn.fnamemodify(filepath, ":p:h")
  local toplevel = vim.fn.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 then return dir end
  return vim.trim(toplevel)
end

local function relative_to(filepath, root)
  local prefix = root .. "/"
  if filepath:sub(1, #prefix) == prefix then return filepath:sub(#prefix + 1) end
  return filepath
end

-- A headless `-p` run is not a session anything can be pasted into. Excluding it
-- matters because `:ClaudeOverview` spawns one as a child of nvim, which would
-- otherwise make nvim's own pane look like a Claude pane for the duration.
local function is_headless_run(args)
  for token in args:gmatch("%S+") do
    if token == "-p" or token == "--print" then return true end
  end
  return false
end

-- The first token's basename, so `nvim ~/.claude/notes.md` is not mistaken for a session.
local function is_claude_command(args)
  local executable = args:match("^(%S+)")
  if not executable then return false end
  local basename = vim.fn.fnamemodify(executable, ":t")
  local is_claude = basename == "claude" or (basename:match("^node") and args:match("/claude"))
  return is_claude and not is_headless_run(args)
end

-- A pane counts either way: started by hand, its shell is claude's parent; spawned
-- by us, `claude` is the pane process itself. Missing the second case made the pane
-- we had just opened invisible, so every call spawned another one.
local function pids_running_claude()
  local pids = {}
  for _, line in ipairs(vim.fn.systemlist("ps -Ao pid=,ppid=,args=")) do
    local pid, parent_pid, args = line:match("^%s*(%d+)%s+(%d+)%s+(.+)$")
    if pid and is_claude_command(args) then
      pids[pid] = true
      pids[parent_pid] = true
    end
  end
  return pids
end

-- Bare `list-panes` is this window only, which is the whole scoping rule: a session
-- in another window or another tmux session is a different workspace and is never
-- looked at, let alone reused. No pane here means spawn one here.
local function claude_panes_in_window()
  local running = pids_running_claude()
  local panes = {}
  for _, line in ipairs(vim.fn.systemlist("tmux list-panes -F '#{pane_id} #{pane_pid}'")) do
    local pane_id, pane_pid = line:match("^(%%%d+) (%d+)$")
    if pane_id and running[pane_pid] then table.insert(panes, pane_id) end
  end
  return panes
end

local function paste_into_pane(pane_id, content)
  local tmpfile = vim.fn.tempname()
  vim.fn.writefile(vim.fn.split(content, "\n"), tmpfile)
  vim.fn.system(string.format("tmux load-buffer '%s'", tmpfile))
  vim.fn.system(string.format("tmux paste-buffer -t '%s'", pane_id))
  vim.fn.system(string.format("tmux send-keys -t '%s' Enter", pane_id))
  vim.fn.delete(tmpfile)
end

-- The input box: a `❯` line inside the rules Claude draws. His shell prompt uses neither.
local function shows_input_prompt(capture)
  return capture:find("\n❯", 1, true) ~= nil and capture:find("───", 1, true) ~= nil
end

local function when_pane_ready(pane_id, deadline, on_ready)
  vim.system({ "tmux", "capture-pane", "-pt", pane_id }, { text = true }, function(result)
    local ready = shows_input_prompt(result.stdout or "")
    vim.schedule(function()
      if ready then return on_ready() end
      if vim.loop.now() > deadline then
        return notify("pane did not finish starting up; nothing was sent", vim.log.levels.ERROR)
      end
      vim.defer_fn(function() when_pane_ready(pane_id, deadline, on_ready) end, PROMPT_POLL_INTERVAL_MS)
    end)
  end)
end

-- `-d` keeps focus in nvim while it boots; select-pane moves it once there is something to read.
local function spawn_claude_pane(cwd, on_ready)
  local command = string.format(
    "tmux split-window -h -d -c %s -P -F '#{pane_id}' claude",
    vim.fn.shellescape(cwd)
  )
  local pane_id = vim.trim(vim.fn.system(command))
  if vim.v.shell_error ~= 0 or not pane_id:match("^%%%d+$") then
    return notify("could not open a pane: " .. pane_id, vim.log.levels.ERROR)
  end
  notify("starting a session in a new pane…")
  when_pane_ready(pane_id, vim.loop.now() + PROMPT_TIMEOUT_MS, function() on_ready(pane_id) end)
end

vim.api.nvim_create_user_command("Claude", function(opts)
  local start_line = opts.line1
  local end_line   = opts.line2
  local lines      = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local filepath   = vim.fn.expand("%:~:.")
  local filetype   = vim.bo.filetype

  local content = string.format(
    "`%s` lines %d-%d:\n```%s\n%s\n```\n\n%s",
    filepath, start_line, end_line, filetype,
    table.concat(lines, "\n"),
    opts.args
  )

  local panes = claude_panes_in_window()
  if #panes > 1 then
    return notify("several sessions are running in this window; aborting", vim.log.levels.ERROR)
  end
  if #panes == 1 then return paste_into_pane(panes[1], content) end

  spawn_claude_pane(repo_root_for(vim.fn.expand("%:p")), function(pane_id)
    paste_into_pane(pane_id, content)
    vim.fn.system(string.format("tmux select-pane -t '%s'", pane_id))
  end)
end, { range = true, nargs = "+" })

local function open_overview_buffer(title, lines)
  vim.cmd("vsplit")
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buffer)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].filetype = "markdown"
  vim.bo[buffer].modifiable = false
  vim.api.nvim_buf_set_name(buffer, "claude://overview/" .. title)
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buffer, nowait = true })
end

vim.api.nvim_create_user_command("ClaudeOverview", function()
  if vim.bo.modified then
    return notify("buffer has unsaved changes — Claude reads from disk, so write it first",
      vim.log.levels.ERROR)
  end

  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    return notify("this buffer is not a file", vim.log.levels.ERROR)
  end

  local root = repo_root_for(filepath)
  local relative = relative_to(filepath, root)

  notify("reading " .. relative .. "…")

  -- The prompt goes on stdin: `--allowedTools` is variadic and eats a trailing positional.
  vim.system({
    "claude", "-p",
    "--model", "sonnet",
    "--output-format", "text",
    "--permission-prompts", "none",
    "--allowedTools", "Read Grep Glob",
  }, {
    cwd = root,
    text = true,
    stdin = string.format(OVERVIEW_PROMPT, relative),
  }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local reason = vim.trim(result.stderr or "")
        return notify("overview failed: " .. (reason ~= "" and reason or "exit " .. result.code),
          vim.log.levels.ERROR)
      end
      local output = vim.trim(result.stdout or "")
      if output == "" then
        return notify("overview came back empty", vim.log.levels.WARN)
      end
      open_overview_buffer(relative, vim.fn.split(output, "\n"))
    end)
  end)
end, {})
