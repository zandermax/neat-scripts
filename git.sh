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

# Pull all changes in all git repos in a directory
pullAll() {
	# Initialize an empty string to store directories with errors
	error_dirs=""

	# Loop through all subdirectories
	for d in */; do
		if [ -d "$d/.git" ]; then # Check if the directory is a Git repository
			echo "Pulling in $d"
			# Attempt to pull, redirecting errors to a temp file
			if ! (cd "$d" && git pull) 2>/tmp/error$$; then
				echo "Error in $d"
				# Append the directory and error message to the error_dirs string
				error_dirs+="$d: $(cat /tmp/error$$)\n"
			fi
		fi
	done

	# Check if there were any errors
	if [ -n "$error_dirs" ]; then
		echo -e "Errors occurred in the following directories:\n$error_dirs"
	else
		echo "Git pull successful in all directories."
	fi

	# Clean up the temporary error file
	rm -f /tmp/error$$
}

# Shows all repos in a directory that have useful changes
alias rgits="runGitCommandInDirs 'git status -s | grep -v \".DS_Store\"'"

# Commit all changes in all git repos in a directory, with the same
commitall() {
	runGitCommandInDirs "git commit -m \"$1\""
}

alias pushnew='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'
