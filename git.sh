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
run-git-command-in-dirs() {
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
pull-all() {
	# Initialize an empty string to store directories with errors
	error_dirs=""
	# Loop through all subdirectories
	for d in */; do
		if [ -d "$d/.git" ]; then # Check if the directory is a Git repository
			# check if on master branch
			if [ "$(cd "$d" && git rev-parse --abbrev-ref HEAD)" != "master" ]; then
				echo "Not on master branch in $d, skipping"
				continue
			fi
			# Stash any changes, attempt to pull, redirecting errors to a temp file
			echo "Pulling in $d"
			if ! (cd "$d" && git stash && git pull) 2>/tmp/error$$; then
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
alias rgits="run-git-command-in-dirs 'git status -s | grep -v \".DS_Store\"'"

# Commit all changes in all git repos in a directory, with the same
commit-all() {
	run-git-command-in-dirs "git commit -m \"$1\""
}

rename-branch() {
	# Get current branch name
	current_branch=$(git rev-parse --abbrev-ref HEAD)
	# Rename branch
	git branch -m "$current_branch" "$1"
	# Check if remote branch exists, if so delete it
	if git show-ref --verify --quiet "refs/remotes/origin/$current_branch"; then
		git push origin --delete "$current_branch" --no-verify
	fi
	# Push new branch and set upstream
	git push --set-upstream origin "$1" --no-verify
}

alias push-new-branch='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'
