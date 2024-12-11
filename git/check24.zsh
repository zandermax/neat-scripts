MULTI_REPO_DIR=~/bu-repos-all
WORKSPACES_DIR="$MULTI_REPO_DIR/__workspaces"

alias force_push="git push --force-with-lease"

# Pushes with checks for common caveats
# @param --allow-master - allow pushing changes from the master branch
# @param --force - run --force-with-lease
# @param $@ - additional arguments to git push
push() {
	allow_master=false
	force=''
	additional_args=''

	typeset -A switch_to_command_and_description=(
		"--allow-master" "allow_master=true|Allow pushing to the master branch"
		"--force" "force='--force-with-lease'|Force push (with lease)"
	)

	while [ $# -gt 0 ]; do
		if [[ "$1" == "--help" ]]; then
			print_help_cmd="print_help push 'Push changes to the remote repository'"
			for key in "${(@k)switch_to_command_and_description}"; do
				description="${switch_to_command_and_description[$key]#*|}"
				print_help_cmd="$print_help_cmd --switch $key '$description'"
			done

			# Add examples to the help message
			examples=(
				"push --force"
				"push --allow-master"
				"push --force --allow-master"
			)
			for example in "${examples[@]}"; do
				print_help_cmd="$print_help_cmd --example '$example'"
			done

			eval "$print_help_cmd"
			return 0
		elif [[ -n "${switch_to_command_and_description[$1]}" ]]; then
			command="${switch_to_command_and_description[$1]%|*}"
			eval "$command"
			shift
		else
			additional_args+="$1 "
			shift
		fi
	done

	echo "UH OH"
	exit 1

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
		git push "$force" $additional_args --set-upstream origin "$current_branch"
	else
		# Run git push and append any other arguments
		git push "$force" $additional_args
	fi
}

# Reset all repos to the master branch
reset_all() {
	run_command_in_repos "git_sync master --no-switch"

	echo "Reset all repos to the master branch"
	echo

	# Unlink any linked npm packages
	unlink_all_npm
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
	# Check if link already exists, create if not
	if [ -L "$workspace_dir/$current_dir" ]; then
		echo "Link already exists"
	else
		# FIXME This seems to be adding a link inside the project directory as well?
		ln -s "$(pwd)" "$workspace_dir/$current_dir"
	fi

	# 	# Create the workspace file if it doesn't exist
	workspace_file="$WORKSPACES_DIR/VERBU-$issue_number.code-workspace"
	if [ ! -f "$workspace_file" ]; then
		# Create the workspace file
		echo "Creating workspace file $workspace_file"

		echo "{" >"$workspace_file"
		echo '	"folders": [' >>"$workspace_file"
		echo "		{" >>"$workspace_file"
		echo "			"\"name\"": \"$current_dir\"," >>"$workspace_file"
		echo "			"\"path\"": \"../$workspace_dir\"" >>"$workspace_file"
		echo "		" >>"$workspace_file"
		echo "		}" >>"$workspace_file"
		echo "	]" >>"$workspace_file"
		echo "}" >>"$workspace_file"

	else # Add the linked directory to the workspace file
		# TODO: Check if the directory is already in the workspace file, add otherwise
	fi

	# Open the workspace in VS Code
	if $open; then
		code "$workspace_file"
	fi
}

# Switch to all branches with the given issue number prefix
#
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
