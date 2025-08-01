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
alias gpf='git push --force-with-lease'

alias gsw='git switch'
alias gs-='git switch -'

alias gsh='git stash'
alias gshp='git stash pop'

alias push-new-branch='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'

# Fixes the last commit that was pushed by adding any uncommitted changes to the commit
#
# @param --all - optional parameter to add all changes to the commit
git_fix_last_commit() {
	# Check for parameter
	if [ "$1" = "--all" ]; then
		git add .
	fi

	git commit --amend --no-edit
	git push --force-with-lease
}

# Syncs the current branch with the remote branch, and auto-stashes changes if there are any
# The branch is then switched back to the original branch, unless --no-switch is provided
# The stash message can be provided with --stash-message
#
# @param $1: branch name
# @param --no-switch - optional parameter to not switch to the branch after syncing
# @param --stash-message - optional parameter to provide a message for the stash
git_sync() {
	if [ -z "$1" ]; then
		echo "Usage: git_sync <branch> [--no-switch] [--stash-message <message>]"
		return 1
	fi

	branch="$1"

	shift
	#  Parameter switches: --no-switch, --stash-message
	for param in "$@"; do
		case $param in
		--no-switch)
			no_switch=true
			shift
			;;
		--stash-message)
			stash_message="$2"
			shift 2
			;;
		esac
	done

	local repo_name=$(basename "$(pwd)")

	git fetch

	#  check if there are any changes and stash if found
	if ! git diff --quiet; then
		stashed_changes=true
		echo "Changes found in ${repo_name}, stashing"
		if [ -n "$stash_message" ]; then
			git stash -m "$stash_message"
		fi
	fi

	# Suppress "already on branch" message
	current_branch=$(git rev-parse --abbrev-ref HEAD)
	if [ "$current_branch" = "$branch" ]; then
		git pull >/dev/null 2>&1
		return 0
	fi

	# Only pull if result of git switch is not "Your branch is up to date with 'origin/branch'"
	switch_command=$(git switch "$branch" 2>&1)
	if [ "$switch_command" != "Your branch is up to date with 'origin/$branch'." ]; then
		git pull
	fi

	if [ "$no_switch" != true ]; then
		echo "Switching to $branch"
		git switch -
		git merge "$branch"

		if [ "$stashed_changes" = true ]; then
			echo "Applying stashed changes"
			git stash apply
		fi

	fi
}

# Renames a branch, both locally and remotely
#
# @param $1: new branch name
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

# Squashes a given number of commits
#
# @param $1: number of commits to squash
git_squash_commits() {
	# Check for parameter
	if [ -z "$1" ]; then
		echo "Usage: git_squash_commits <number_of_commits>"
		return 1
	fi
	commits_to_squash=$1
	git rebase -i HEAD~$commits_to_squash
}

git_squash_since_branch() {
	#  Check for parameter
	if [ -z "$1" ]; then
		echo "Usage: git_squash_since_branch <branch> [-m <message>]"
		return 1
	fi

	git_sync "$1"
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

# Checks out a branch with a given prefix
#  If the branch is not found locally, it will check remote branches
#  Local changes are stashed accordingly
#  This is useful for switching issues
#
# @param $1: prefix (e.g. feature/VERBU-123)
# @param --no-output - optional parameter to suppress output
# @param --pull - optional parameter to pull changes after switching
# @param --success-only - optional parameter to only show success messages
checkout_branch_with_prefix() {
	prefix=$1
	output_level=all
	remote=false

	shift
	# Parse parameters
	for param in "$@"; do
		case $param in
		--no-output)
			output_level=none
			shift
			;;
		--pull)
			pull=true
			shift
			;;
		--success-only)
			output_level=success
			shift
			;;
		esac
	done

	# Gets any local (not remote) branches that start with the branch_prefix
	local_branches=$(git branch | grep "$prefix" | sed "s/^[ *]*//")
	if [ -z "$local_branches" ]; then
		echo "No local branches found matching $prefix"
	fi

	# If no local branches are found, check remote branches
	if [ -z "$local_branches" ]; then
		remote_branches=$(git branch -r | grep "origin/$prefix" | sed "s/^[ *]*origin\///")
		if [ -z "$remote_branches" ]; then
			echo "No remote branches found matching $prefix, exiting"
			return 1
		fi
	fi

	#  Get the most recent branch, by looking at the most recent commit
	most_recent_branch=$(echo "$local_branches" | tail -n 1)

	#  If there are any uncommitted changes, stash them
	if [[ -n "$(git status --porcelain)" ]]; then
		# git stash push -m "Switching to $prefix"
		git stash push -m 'Switching to $prefix'
	fi

	#  Switch to the most recent branch, if not already on it
	if [ "$most_recent_branch" != "$(git rev-parse --abbrev-ref HEAD)" ]; then
		# git checkout "$most_recent_branch"
		git checkout $most_recent_branch
	else
		echo "Already on $most_recent_branch"
	fi
}

# Squashes all commits since branch was created
#  The first commit message is used as the new commit message
#  The branch is then force pushed
#
# @param $1: branch name that the current branch was created from [default: master]
squish() {
	# Make sure we are not on master
	if [ "$(git rev-parse --abbrev-ref HEAD)" = "master" ]; then
		echo "Cannot squash commits on master"
		return 1
	fi

	branch_created_from=${1:-master}

	# Sync with master
	git_sync master

	# Get first commit message on the branch since it was created
	first_commit_message=$(git log --pretty=format:%s $(git merge-base HEAD "$branch_created_from")..HEAD | tail -n 1)

	# Squash commits
	git_squash_since_branch "$branch_created_from" -m "$first_commit_message"

	# Push changes
	gpf
}

# Syncs a branch from the fork point at which it was created
# e.g. this will rebase the current branch on top of the branch it was created from
sync_fork() {
	git fetch
	git rebase $(git merge-base --fork-point HEAD)
}

#  Function aliases
alias fix-commit='git_fix_last_commit'
alias fix-commit-all='git_fix_last_commit --all'
alias squash-branch='git_squash_since_branch'
alias squash='git_squash_commits'
alias git-node='git_nodefiles_from_branch'
