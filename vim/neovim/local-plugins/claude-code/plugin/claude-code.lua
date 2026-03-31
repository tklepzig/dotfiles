vim.api.nvim_create_user_command("Claude", function(opts)
  local start_line = opts.line1
  local end_line   = opts.line2
  local lines      = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local filepath   = vim.fn.expand('%:~:.')
  local filetype   = vim.bo.filetype
  local message    = opts.args

  local raw = vim.fn.system("tmux list-panes -F '#{pane_id} #{pane_pid}'")
  local claude_panes = {}
  for pane_id, shell_pid in raw:gmatch("(%%%d+) (%d+)") do
    local child_pids = vim.fn.system("pgrep -P " .. shell_pid)
    for child_pid in child_pids:gmatch("%d+") do
      local args = vim.fn.system("ps -p " .. child_pid .. " -o args= 2>/dev/null")
      if args:match("claude") then
        table.insert(claude_panes, pane_id)
        break
      end
    end
  end

  if #claude_panes == 0 then
    vim.notify("Claude: no tmux pane running claude found", vim.log.levels.ERROR)
    return
  end

  if #claude_panes > 1 then
    vim.notify("Claude: multiple panes running claude found, aborting", vim.log.levels.ERROR)
    return
  end

  local target = claude_panes[1]

  local content = string.format(
    "`%s` lines %d-%d:\n```%s\n%s\n```\n\n%s",
    filepath, start_line, end_line, filetype,
    table.concat(lines, '\n'),
    message
  )

  local tmp = vim.fn.tempname()
  vim.fn.writefile(vim.fn.split(content, '\n'), tmp)
  vim.fn.system(string.format("tmux load-buffer '%s'", tmp))
  vim.fn.system(string.format("tmux paste-buffer -t '%s'", target))
  vim.fn.system(string.format("tmux send-keys -t '%s' Enter", target))
  vim.fn.delete(tmp)
end, { range = true, nargs = "+" })
