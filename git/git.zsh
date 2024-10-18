#!/bin/bash

# General git aliases
alias g='git'
alias gs='git status'
alias gf='git fetch'
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'

alias push-new-branch='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'

git_fix_last_commit() {
	git add .
	git commit --amend --no-edit
	git push --force-with-lease
}

git_nodefiles_from_branch() {
	# Check for parameter
	if [ -z "$1" ]; then
		echo "Usage: git_node_from_branch <branch>"
		return 1
	fi

	# Always use incoming changes if there are conflicts
	git checkout "$1" --theirs package.json yarn.lock
}

git_sync() {
	# Check for parameter
	if [ -z "$1" ]; then
		echo "Usage: git_sync <branch>"
		return 1
	fi

	#  check if there are any changes
	if ! git diff-index --quiet HEAD --; then
		echo "There are changes in the working directory. Stashing changes before sync."
		git stash -m "Stashing changes before sync"
		stashed_changes=true
	fi

	git switch "$1"
	git fetch
	git pull

	git switch -
	git merge "$1"

	if [ "$stashed_changes" = true ]; then
		git stash apply
	fi
}

git_rename_branch() {
	# Check for parameter
	if [ -z "$1" ]; then
		echo "Usage: git_rename_branch <new_branch_name>"
		return 1
	fi
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

git_squash_commits() {
	# Check for parameter
	if [ -z "$1" ]; then
		echo "Usage: git_squash_commits <number_of_commits>"
		return 1
	fi
	commits_to_squash=$1
	git rebase -i HEAD~$commits_to_squash
	git push --force-with-lease
}

git_squash_since_branch() {
	#  Check for parameter, or if is is -m
	if [ -z "$1" ] || [ "$1" = "-m" ]; then
		echo "Usage: git_squash_since_branch <branch> [-m <message>]"
		return 1
	fi

	git reset --hard $(git merge-base HEAD $1)
	git merge --squash HEAD@{1}

	# check for -m parameter, use as the commit message
	# Otherwise, open the editor
	if [ "$2" = "-m" ]; then
		git commit -m "$3"
	else
		git commit
	fi
}
