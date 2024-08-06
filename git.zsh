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
run_command_in_repos() {
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

fetch_all() {
	for d in */; do
		if [ -d "$d/.git" ]; then
			echo "Fetching in $d"
			(cd "$d" && git fetch)
		fi
	done
}

# Pull all changes in all git repos in a directory
pull_all() {
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
			echo ""
		fi
	done

	# Check if there were any errors
	if [ -n "$error_dirs" ]; then
		echo -e "Errors occurred in the following directories:\n$error_dirs"
	else
		echo "Git pull successful in all directories."
		echo ""
	fi

	# Clean up the temporary error file
	rm -f /tmp/error$$
}

# Shows all repos in a directory that have useful changes
alias rgits="run-git-command-in-dirs 'git status -s | grep -v \".DS_Store\"'"

# Commit all changes in all git repos in a directory, with the same
commit_all() {
	run_command_in_repos "git commit -m \"$1\""
}

# Finds all branches with unpushed or unpublished commits in all subdirectories
# Parameters:
# $1: Branch prefix to search for (optional)
# Options:
# --publish: Publishes all unpublished branches found
find_unpushed() {
	branch_prefix=""
	publish_unpublished=false

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case $1 in
		--publish)
			publish_unpublished=true
			shift
			;;
		*)
			branch_prefix=$1
			shift
			;;
		esac
	done

	found_dirs_unpublished=""
	found_dirs_uncommitted=""

	# Loop through each subdirectory
	for dir in */; do
		if [ -d "$dir/.git" ]; then
			echo
			echo "Checking $dir"
			cd "$dir" || continue

			if [ -n "$branch_prefix" ]; then
				# Check if any branch starting with the given prefix has unpushed or unpublished commits
				for branch in $(git branch --list "$branch_prefix*"); do
					# Filter out the case where branch is exactly '*'
					if [ "$branch" != "*" ]; then
						echo "Checking branch $branch"
						if git status -uno | grep -q "Your branch is ahead of"; then
							echo "Branch '$branch' with unpushed commits found in: $dir"
							found_dirs_uncommitted+="$dir\n"
							break
						elif ! git show-ref --quiet --verify "refs/remotes/origin/$branch"; then
							echo "Branch '$branch' is unpublished in: $dir"
							found_dirs_unpublished+="$dir\n"
							if [ "$publish_unpublished" = true ]; then
								echo "Publishing branch '$branch' to remote in: $dir"
								git push -u origin "$branch"
							fi
							break
						fi
					fi
				done
			else
				# Check if the current branch has unpushed or unpublished commits
				if git status -uno | grep -q "Your branch is ahead of"; then
					echo "Branch with unpushed commits found in: $dir"
					found_dirs_uncommitted+="$dir\n"
				elif ! git show-ref --quiet --verify "refs/remotes/origin/$(git rev-parse --abbrev-ref HEAD)"; then
					echo "Branch is unpublished in: $dir"
					found_dirs_unpublished+="$dir\n"
					if [ "$publish_unpublished" = true ]; then
						echo "Publishing branch to remote in: $dir"
						git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
					fi
				fi
			fi

			cd - >/dev/null || exit
		fi
	done

	echo
	# Output all directories where branches with unpushed or unpublished commits were found
	if [ -n "$found_dirs_uncommitted" ]; then
		echo -e "\nBranches with unpushed commits were found in the following directories:\n$found_dirs_uncommitted"
	fi
	if [ -n "$found_dirs_unpublished" ]; then
		echo -e "\nBranches with unpublished commits were found in the following directories:\n$found_dirs_unpublished"
	fi
	if [ -z "$found_dirs_uncommitted" ] && [ -z "$found_dirs_unpublished" ]; then
		echo "No branches with unpushed or unpublished commits were found in any directories."
	fi
}

rename_branch() {
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
