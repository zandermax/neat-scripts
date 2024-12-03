MULTI_REPO_DIR=~/bu-repos-all

push() {
	# Parse arguments
	allow_master=false
	while [ $# -gt 0 ]; do
		case "$1" in
		--allow-master)
			allow_master=true
			shift
			;;
		*)
			break
			;;
		esac
	done

	# Check if on master branch and quit with a warning unless --allow-master is set
	current_branch=$(git rev-parse --abbrev-ref HEAD)
	if [ "$current_branch" = "master" ] && [ "$allow_master" = false ]; then
		echo "$stars"
		echo "$stars"
		echo "Error: You are on the master branch. Use --allow-master to allow pushing changes."
		echo "$stars"
		echo "$stars"
		return 1
	fi

	# Check if there are any dependencies with '-verbu-' in package.json, which requires migration
	if grep -q '"[^"]*-verbu-[^"]*"' package.json; then
		echo "$stars"
		echo "$stars"
		echo "Warning: A dependency with '-verbu-' was found in package.json."
		echo "Do not forget to run the migration script!"
		echo "$stars"
		echo "$stars"
	fi

	# Check if there is an upstream branch being tracked
	if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
		echo "No upstream branch found. Setting upstream to origin/$current_branch."
		git push --set-upstream origin "$current_branch" "$@"
	else
		# Run git push and append any other arguments
		git push "$@"
	fi
}

pull_all_master() {
	#  Parameters: --stash-message <message>
	for param in "$@"; do
		case $param in
		--stash-message)
			stash_message="$2"
			shift 2
			;;
		esac
	done

	run_command_in_repos "git_sync master --no-switch --stash-message $stash_message"
}

reset_all() {
	run_command_in_repos "git_sync master"
}

# @param $1: issue number
# @param --sync - sync before switching
# @param --sync-branch - sync the branch after switching
switch_issue() {
	# Check for parameter
	if [ -z "$1" ]; then
		echo "Usage: switch_issue <issue_number> [--sync]"
		return 1
	fi

	# Change to multi-repo_dir
	cd "$MULTI_REPO_DIR" || return 1

	# Issue number is always the first parameter
	issue_number="$1"

	# Remove the first parameter
	shift

	# Parse arguments
	sync=false
	sync_branch=false
	for param in "$@"; do
		case "$param" in
		--sync)
			sync=true
			shift
			;;
		--sync-branch)
			sync_branch=true
			shift
			;;
		esac
	done

	branch_prefix="feature/VERBU-$issue_number"

	printf "Switching to branches with prefix %s\n\n" "$branch_prefix"

	# Run the command and capture the output
	if $sync; then
		cmd="git_sync && checkout_branch_with_prefix $branch_prefix"
	else
		cmd="checkout_branch_with_prefix $branch_prefix --success-only"
	fi

	if $sync_branch; then
		cmd="$cmd --pull"
	fi

	run_command_in_repos --no-output "$cmd"
}
