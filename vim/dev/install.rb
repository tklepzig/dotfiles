#!/usr/bin/env ruby
# frozen_string_literal: true

check_optional_installation 'ag', 'silversearcher-ag'
check_optional_installation 'ranger'
check_optional_installation 'fzf'
check_optional_installation 'bat'

`mkdir -p #{HOME}/.vim`
`ln -sf #{DF_PATH}/vim/dev/coc-settings.json #{HOME}/.vim/coc-settings.json`
