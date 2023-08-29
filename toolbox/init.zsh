#!/usr/bin/env zsh

scripts_path="$HOME/.dotfiles/toolbox/scripts"
local_scripts_path="$HOME/.local-scripts"

if [ -d "$local_scripts_path" ]
then
	for file in "$local_scripts_path"/*
	do
		ln -sf "$file" "$scripts_path"
	done
fi

cmds=( $($scripts_path/_run.rb --list-short) )
# ${(f)...} --> parameter expansion, split at new lines
descs=( ${(f)"$($scripts_path/_run.rb --list)"} )

scripts_completion() {
	#see also https://stackoverflow.com/a/73356136
	if [[ $CURRENT == 3 ]]
	then
		shift words
		((CURRENT--))
		# TODO get custom completions from yaml
		# by call _run.rb with current script name
		# (which is in $words after the shift)
		# e.g.
		# completions:
		# - show
		# - serve
		# - test
		# completions=( $($scripts_path/_run.rb --completions $words) )
		# compadd -a completions
		# Or maybe improve it by putting all available completions into 
		# a variable to avoid opening the yaml file everytime a completion
		# is invoked, so sth like
		# custom_completions=( $($scripts_path/_run.rb --completions) )
		# custom_completions should be then sth like a dictionary
		
		# if no custom completion exists use the line below for file system completion
		_normal -p \#
	else
		#compadd -d descs -a cmds
		#compadd -a cmds
		_describe -t descs 'commands' descs
	fi
}
compdef scripts_completion \#

\#() {
	if [ $# -eq 0 ]
	then
		args=$(printf "%s\n" "${cmds[@]}" | fzf | awk '{print $1}')
	else
		args=( $@ )
	fi

	cmd=$($scripts_path/_run.rb $args)
	if [ $? -ne 0 ]
	then
		echo "$cmd"
	else
		[ $# -ne 0 ] && shift

		first_line=$(head -n 1 "$scripts_path/$cmd")
		[[ $first_line != \#!* ]] && echo "Error: $cmd is missing a proper shebang line" && return 1

		export dotfiles_path="$HOME/.dotfiles"
		export dotfiles_os="${$(uname):l}"

		"$scripts_path/$cmd" $@
	fi
}
