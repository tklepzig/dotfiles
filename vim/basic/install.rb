#!/usr/bin/env ruby
# frozen_string_literal: true

`mkdir -p #{HOME}/.vim/backup`
`mkdir -p #{HOME}/.vim/.swp`
`mkdir -p #{HOME}/.vim/.undo`

if ENV['DOTFILES_NVIM']
  `mkdir -p #{HOME}/.config/nvim`
  `ln -sf #{DF_PATH}/vim/nvim-init.vim #{HOME}/.config/nvim/init.vim`
end
