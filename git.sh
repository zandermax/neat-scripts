#!/bin/bash

# General git aliases
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'

# Run command in all git repos in a directory with changes
# Parameters:
# $1: Command to run
runGitCommandInDirs() {
	local cmd="$1" # Command to run
	for d in */; do
		(
			cd "$d" && git status -s | grep -v ".DS_Store" >/dev/null
			if [ $? -eq 0 ]; then
				echo "In $d"
				eval "$cmd"
				echo ""
			fi
		)
	done
}

# Shows all repos in a directory that have useful changes
alias rgits="runGitCommandInDirs 'git status -s | grep -v \".DS_Store\"'"

# Commit all changes in all git repos in a directory, with the same
commitall() {
	runGitCommandInDirs "git commit -m \"$1\""
}

alias pushnew='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'
