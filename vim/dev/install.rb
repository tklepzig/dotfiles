#!/usr/bin/env ruby
# frozen_string_literal: true

check_optional_installation 'ag', 'the_silver_searcher'
check_optional_installation 'ranger'
check_optional_installation 'bat'

`mkdir -p #{HOME}/.vim`
`ln -sf #{DF_PATH}/vim/dev/coc-settings.json #{HOME}/.vim/coc-settings.json`

if ENV['DOTFILES_NVIM']
  `mkdir -p #{HOME}/.config/nvim`
  `ln -sf #{DF_PATH}/vim/dev/coc-settings.json #{HOME}/.config/nvim/coc-settings.json`
end
