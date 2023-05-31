setopt autocd

source $dotfilesDir/zsh/basic/alias.override.zsh

# Setting rg as the default source for fzf (respects .gitgnore by default)
export FZF_DEFAULT_COMMAND='rg --files'
# To apply the command to CTRL-T as well
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
