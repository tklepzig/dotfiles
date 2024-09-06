#!/usr/bin/env ruby
# frozen_string_literal: true

`mkdir -p #{HOME}/.vim/backup`
`mkdir -p #{HOME}/.vim/.swp`
`mkdir -p #{HOME}/.vim/.undo`

if ENV['DOTFILES_NVIM']
  `mkdir -p #{HOME}/.config/nvim/lua/tkdf`
  `ln -sf #{DF_PATH}/vim/nvim-init.vim #{HOME}/.config/nvim/init.vim`
  `ln -sf #{DF_PATH}/vim/nvim-plugin-config.lua #{HOME}/.config/nvim/lua/tkdf/plugin-config.lua`
  `ln -sf #{DF_PATH}/vim/module-available.lua #{HOME}/.config/nvim/lua/tkdf/module-available.lua`
  `ln -sf #{DF_PATH}/vim/nvim-plugins/* #{HOME}/.config/nvim/lua/tkdf`
end
