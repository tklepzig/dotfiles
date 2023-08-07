#!/usr/bin/env zsh
		
scripts_path="$HOME/.dotfiles/toolbox/scripts"

isOS()
{
  if [[ "$OSTYPE:l" == *"$1:l"* ]]
  then
    return 0;
  fi

  return 1;
}
		
cmds=( $($scripts_path/run.rb --list) )

scripts_completion() {
	compadd -a cmds
}
compdef scripts_completion \#

\#() {
	if [ $# -eq 0 ]
	then
		args=$(printf "%s\n" "${cmds[@]}" | fzf | awk '{print $1}')
	else
		args=( $@ )
	fi

	cmd=$($scripts_path/run.rb $args)
	if [ $? -ne 0 ]
	then
		echo "$cmd"
	else
		[ $# -ne 0 ] && shift

		first_line=$(head -n 1 "$scripts_path/$cmd")
		[[ $first_line != \#!* ]] && echo "Error: $cmd is missing a proper shebang line" && return 1
		"$scripts_path/$cmd" $@
	fi
}

