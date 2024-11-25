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
		echo "Usage: git_sync <branch> [--no-switch] [--stash-message <message>]"
		return 1
	fi

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

	#  check if there are any changes
	if ! git diff-index --quiet HEAD --; then
		echo "There are changes in the working directory. Stashing changes before sync."
		if [ -z "$stash_message" ]; then
			stash_message="Stashing changes before sync"
		fi
		git stash -m "$stash_message"
		stashed_changes=true
	fi

	git switch "$1"
	git fetch
	git pull

	if [ "$no_switch" != true ]; then
		git switch -
		git merge "$1"

		if [ "$stashed_changes" = true ]; then
			git stash apply
		fi

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

# @param $1: prefix
# @param --no-output - optional parameter to suppress output
#  @param --pull - optional parameter to pull changes after switching
checkout_branch_with_prefix() {
	prefix=$1
	no_output=false

	shift
	# Check for --no-output parameter
	for param in "$@"; do
		if [ "$param" = "--no-output" ]; then
			no_output=true
			shift
		fi
	done

	repo_name=$(basename "$(pwd)")

	if [ "$no_output" != true ]; then
		echo "Checking out branch with prefix $prefix"
	fi

	# Command to check for branches with the given prefix and switch to the branch if it exists
	branch=$(git branch --list "$prefix*" | head -n 1)
	if [ -n "$branch" ]; then
		branch_name=$(echo "$branch" | sed 's/^[* ]*//')
		if [ "$no_output" = true ]; then
			git switch "$branch_name" >/dev/null 2>&1
		else
			git switch "$branch_name"
		fi

		if [ "$1" = "--pull" ]; then
			git pull
		fi

		printf "- %s\n" "$repo_name"
		printf "-> %s\n\n" "$branch_name"
	else
		if [ "$no_output" != true ]; then
			echo "No branch found with prefix $prefix"
		fi
	fi
}

squish() {
	# Get changes
	git fetch
	git_sync master --no-switch

	# Get branch name that this branch was created from
	branch_created_from=$(git merge-base HEAD master)

	# Get first commit message on the branch since it was created
	first_commit_message=$(git log --pretty=format:%s $(git merge-base HEAD "$branch_created_from")..HEAD | tail -n 1)
	"$branch_created_from" -m "$first_commit_message"a

	# Squash commits
	git_squash_since_branch "$branch_created_from" -m "$first_commit_message"

	# Push changes
	gpf
}

#  Function aliases

alias fix-commit='git_fix_last_commit'
alias squash-branch='git_squash_since_branch'
alias squash='git_squash_commits'
alias git-node='git_nodefiles_from_branch'
