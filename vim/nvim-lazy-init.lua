local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = require("tkdf.lazy-plugins")

local function load_override(path)
  local expanded = vim.fn.expand(path)
  if vim.fn.filereadable(expanded) == 1 then
    local ok, extra = pcall(dofile, expanded)
    if ok and type(extra) == "table" then
      vim.list_extend(plugins, extra)
    end
  end
end

-- Repo-level plugin override (e.g. provided by a downstream dotfiles repo).
-- Same role as vim/vim/plugins.override.vim for the vim profile.
load_override("$HOME/.dotfiles/vim/nvim-lazy-plugins.override.lua")

-- User-level local plugin override (~/.dotfiles-local/lazy-plugins.lua).
-- Same role as ~/.dotfiles-local/plugins.vim for the vim profile.
load_override("$HOME/.dotfiles-local/lazy-plugins.lua")

require("lazy").setup(plugins, {
  -- Colorscheme used by lazy.nvim's own UI during plugin installation only.
  install = { colorscheme = { "codedark" } },
})

local theme = vim.env.DOTFILES_THEME or 'lcars'
if theme:match('%-light$') then
  pcall(vim.cmd.colorscheme, "onehalflight")
else
  pcall(vim.cmd.colorscheme, "codedark")
end

-- Re-apply highlight overrides after the colorscheme resets them (both themes).
vim.cmd("source " .. vim.fn.expand("$HOME/.dotfiles/vim/vim/highlight-overrides.vim"))

if theme:match('%-light$') then
  vim.cmd("hi CursorLine ctermbg=251")
end
