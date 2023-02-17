source $dotfilesDir/zsh/ruby/alias.zsh

export ASDF_RUBY_BUILD_VERSION=master
# Don't do that, some gems don't care about frozen and will crash with this set as default
#export RUBYOPT=--enable-frozen-string-literal

# In case instaling ruby via asdf fails due to missing header files, try the following
#export RUBY_CONFIGURE_OPTS="--with-zlib-dir=$(brew --prefix zlib) --with-openssl-dir=$(brew --prefix openssl@3) --with-readline-dir=$(brew --prefix readline) --with-libyaml-dir=$(brew --prefix libyaml)"
