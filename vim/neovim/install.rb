#!/usr/bin/env ruby
# frozen_string_literal: true

check_optional_installation 'rg', 'ripgrep'
check_optional_installation 'ranger'
check_optional_installation 'bat'

`mkdir -p #{HOME}/.vim`
`ln -sf #{DF_PATH}/vim/neovim/coc-settings.json #{HOME}/.vim/coc-settings.json`

`mkdir -p #{HOME}/.config/solargraph`
`ln -sf #{DF_PATH}/vim/neovim/solargraph.yaml #{HOME}/.config/solargraph/config.yml`

`mkdir -p #{HOME}/.config/nvim`
`ln -sf #{DF_PATH}/vim/neovim/coc-settings.json #{HOME}/.config/nvim/coc-settings.json`

`mkdir -p #{HOME}/.config/nvim/lua/tkdf`
`ln -sf #{DF_PATH}/vim/nvim-init.vim #{HOME}/.config/nvim/init.vim`
`ln -sf #{DF_PATH}/vim/nvim-lazy-init.lua #{HOME}/.config/nvim/lua/tkdf/lazy-init.lua`
`ln -sf #{DF_PATH}/vim/nvim-lazy-plugins.lua #{HOME}/.config/nvim/lua/tkdf/lazy-plugins.lua`
