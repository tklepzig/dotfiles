source $dotfilesDir/zsh/ruby/alias.zsh

export ASDF_RUBY_BUILD_VERSION=master
# Don't do that, some gems don't care about frozen and will crash with this set as default
#export RUBYOPT=--enable-frozen-string-literal

