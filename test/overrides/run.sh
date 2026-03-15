#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local name="$1"
  shift
  if "$@" 2>/dev/null; then
    echo "  PASS  $name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $name"
    FAIL=$((FAIL + 1))
  fi
}

# Run a command headlessly in neovim and succeed if it doesn't call cq.
nvim_check() { nvim --headless -c "$1" -c 'qa' 2>/dev/null; }

echo "Override tests"
echo "=============="

echo ""
echo "-- vimrc overrides"

# setup.rb wires the override by appending a source line to ~/.vimrc.
check "vim  vimrc.override wired into ~/.vimrc" \
  grep -q "vim/vim/vimrc.override" ~/.vimrc

# For neovim we can verify the variable is actually live at runtime.
check "nvim vimrc.override applied at runtime" \
  nvim_check 'if !exists("g:nvim_vimrc_override_test") | cq 1 | endif'

echo ""
echo "-- vim plugins.override.vim"

check "vim  plugins.override.vim removes plugin from plugins.vim" \
  bash -c '! grep -q "mbbill/undotree" ~/.dotfiles/vim/vim/plugins.vim'

echo ""
echo "-- neovim nvim-lazy-plugins.override.lua"

check "nvim nvim-lazy-plugins.override.lua loaded at runtime" \
  nvim_check 'lua if vim.g.nvim_plugins_override_loaded ~= 1 then vim.cmd("cq 1") end'

echo ""
echo "-- user-level local overrides"

# Confirm setup.rb always wires dotfiles-local/plugins.vim and that our
# fixture content was not overwritten by setup.rb's default file creation.
check "vim  ~/.dotfiles-local/plugins.vim sourced from vim/plugins.vim" \
  grep -q ".dotfiles-local/plugins.vim" ~/.dotfiles/vim/plugins.vim

check "vim  ~/.dotfiles-local/plugins.vim contains fixture content" \
  grep -q "local_vim_plugins_test" ~/.dotfiles-local/plugins.vim

check "nvim ~/.dotfiles-local/lazy-plugins.lua loaded at runtime" \
  nvim_check 'lua if vim.g.local_lazy_plugins_loaded ~= 1 then vim.cmd("cq 1") end'

echo ""
echo "=============================="
echo "  $PASS passed, $FAIL failed"
echo "=============================="

[ "$FAIL" -eq 0 ]
