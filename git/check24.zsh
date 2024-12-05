MULTI_REPO_DIR=~/bu-repos-all
WORKSPACES_DIR="$MULTI_REPO_DIR/__workspaces"

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

# Reset all repos to the master branch
reset_all() {
	run_command_in_repos "git_sync master --no-switch"

	echo "Reset all repos to the master branch"
}

# Sync all repos with the master branch
update_all() {
	run_command_in_repos "git_sync master"

	echo "Merged master into all repos"
}

# 1. Creates a new branch with the given param as name
# 2. Links the workspace in the directory for the issue in the workspaces dir,
# 	creating the dir if it doesn't exist
# 3. Adds the linked directory to the VS Code workspace file ($WORKSPACES_DIR/VERBU-$1.code-workspace), creating it if it doesn't exist
# 4. Opens the workspace in VS Code
# @param $1: issue number ($ISSUE_NUMBER)
# @param $2: branch name (appended to 'feature/VERBU-$ISSUE_NUMBER')
#  @ param --open - open the workspace in VS Code
issue_branch() {
	# Check for parameter
	if [ -z "$1" ]; then
		echo "Usage: issue_branch <issue_number>"
		return 1
	fi

	# Issue number is always the first parameter
	issue_number="$1"
	branch_name="$2"

	shift 2
	#  Parse arguments
	open=false
	for param in "$@"; do
		case "$param" in
		--open)
			open=true
			shift
			;;
		esac
	done

	# Convert spaces in branch name to hyphens
	branch_name=$(echo "$branch_name" | tr ' ' '-')

	# Create the branch
	branch_name="feature/VERBU-${issue_number}_${branch_name}"
	echo "Creating branch $branch_name"
	git checkout -b "$branch_name"

	# Create the workspace directory if it doesn't exist
	workspace_dir="$WORKSPACES_DIR/VERBU-$issue_number"
	mkdir -p "$workspace_dir"

	# Name of current directory, without the path
	current_dir=$(basename "$(pwd)")

	# Link the workspace in the directory for the issue in the workspaces dir, named as the current directory
	ln -s "$(pwd)" "$workspace_dir/$current_dir"

	# 	# Create the workspace file if it doesn't exist
	workspace_file="$WORKSPACES_DIR/VERBU-$issue_number.code-workspace"
	if [ ! -f "$workspace_file" ]; then
		# Create the workspace file
		echo "Creating workspace file $workspace_file"

		echo "{" >"$workspace_file"
		echo '	"folders": [' >>"$workspace_file"
		echo "		{" >>"$workspace_file"
		echo "			"\"name\"": \"$current_dir\"," >>"$workspace_file"
		echo "			"\"path\"": \"../$current_dir\"" >>"$workspace_file"
		echo "		}" >>"$workspace_file"
		echo "	]" >>"$workspace_file"
		echo "}" >>"$workspace_file"
	fi

	# Open the workspace in VS Code
	if $open; then
		code "$workspace_file"
	fi
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
