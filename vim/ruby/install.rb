#!/usr/bin/env ruby
# frozen_string_literal: true

`mkdir -p #{HOME}/.config/solargraph`
`ln -sf #{DF_PATH}/vim/ruby/solargraph.yaml #{HOME}/.config/solargraph/config.yml`
`ln -sf #{DF_PATH}/vim/ruby/default-gems #{HOME}/.default-gems`
