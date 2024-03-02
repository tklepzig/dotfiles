#!/usr/bin/env zsh

scripts_path="$HOME/.dotfiles/toolbox/scripts"
local_scripts_path="$HOME/.dotfiles-local/scripts"

if [ -d "$local_scripts_path" ]
then
	for file in "$local_scripts_path"/*
	do
		ln -sf "$file" "$scripts_path"
	done
fi

cmds=( $($scripts_path/_run.rb --list) )
# ${(f)...} --> parameter expansion, split at new lines
descs=( ${(f)"$($scripts_path/_run.rb --details)"} )

scripts_completion() {
	#see also https://stackoverflow.com/a/73356136
	if [[ $CURRENT == 3 ]]
	then
		shift words
		((CURRENT--))

		# After the shift $words contains the current script name
		completion=( ${(f)"$($scripts_path/_run.rb --completion $words)"} )
		if [ -n "$completion" ]
		then
			_describe -t completion 'commands' completion
		else
		# no custom completion exists, use file system completion
			_normal -p \#
		fi
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
