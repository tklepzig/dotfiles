vim.api.nvim_create_user_command("Claude", function(opts)
  local start_line = opts.line1
  local end_line   = opts.line2
  local lines      = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local filepath   = vim.fn.expand('%:~:.')
  local filetype   = vim.bo.filetype
  local message    = opts.args

  local raw = vim.fn.system("tmux list-panes -F '#{pane_id} #{pane_current_command}'")
  local claude_panes = {}
  for pane_id, command in raw:gmatch("(%%%d+) (%S+)") do
    if command == "claude" then
      table.insert(claude_panes, pane_id)
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
