#!/usr/bin/env ruby
# frozen_string_literal: true

check_optional_installation 'rg', 'ripgrep'
check_optional_installation 'ranger'
check_optional_installation 'bat'

`mkdir -p #{HOME}/.vim`
`ln -sf #{DF_PATH}/vim/full/coc-settings.json #{HOME}/.vim/coc-settings.json`

`mkdir -p #{HOME}/.config/solargraph`
`ln -sf #{DF_PATH}/vim/full/solargraph.yaml #{HOME}/.config/solargraph/config.yml`

if ENV['DOTFILES_NVIM']
  `mkdir -p #{HOME}/.config/nvim`
  `ln -sf #{DF_PATH}/vim/full/coc-settings.json #{HOME}/.config/nvim/coc-settings.json`
end
