MULTI_REPO_DIR=~/bu-repos-all
WORKSPACES_DIR="$MULTI_REPO_DIR/__workspaces"

alias force_push="git push --force-with-lease"

# Pushes with checks for common caveats
#
# @param $@ - additional arguments to git push
#
# Switches:
# 	--allow-master - allow pushing to the master branch
# 	--force - force push (with lease)
push() {
	allow_master=false
	force=""
	additional_args=""

	typeset -A switch_to_command_and_description=(
		"--allow-master" "allow_master=true|Allow pushing to the master branch"
		"--force" "force='--force-with-lease'|Force push (with lease)"
	)

	while [ $# -gt 0 ]; do
	# If --help or --? is any argument, use print_help to display the help message
		if [[ "$1" == "--help" ]] || [[ "$1" == "-?" ]]; then
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

	# Trim leading and trailing spaces from additional_args
	additional_args=$(echo "$additional_args" | xargs)

	# Check if on master branch and quit with a warning unless --allow-master is set
	current_branch=$(git rev-parse --abbrev-ref HEAD)
	if [ "$current_branch" = "master" ] && [ "$allow_master" = false ]; then
		echo
		echo "$stars"
		echo "$stars"
		echo "Error: You are on the master branch. Use --allow-master to allow pushing changes."
		echo "$stars"
		echo "$stars"
		echo
		return 1
	fi

	# Check if there are any dependencies with '-verbu-' in package.json, which requires migration
	if grep -q '"[^"]*-verbu-[^"]*"' package.json; then
		echo
		echo "$stars"
		echo "$stars"
		echo "Warning: A dependency with '-verbu-' was found in package.json."
		echo "Do not forget to run the migration script!"
		echo "$stars"
		echo "$stars"
		echo
	fi

	# Check if there is an upstream branch being tracked
	if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
	# [ ] TODO - test this
		echo "No upstream branch found. Setting upstream to origin/$current_branch"
		echo "git command: git push $additional_args --set-upstream origin \$(git rev-parse --abbrev-ref HEAD)"
		git push "$additional_args" --set-upstream origin $(git rev-parse --abbrev-ref HEAD)
	else
		# Run git push and append any other arguments
		git push "$force" "$additional_args"
	fi
}

# Reset all repos to the master branch
reset_all() {

	if [[ "$1" == "--help" ]] || [[ "$1" == "-?" ]]; then
		print_help reset_all "Reset all repos to the master branch
		This will also sync every repo with the origin master branch"
		return 0
	fi

	# Change to multi-repo_dir
	cd "$MULTI_REPO_DIR" || return 1
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

# Function to create or modify the workspace file
workspace_file() {
	full_issue_number="$1"
	current_dir="$2"
	workspace_file="$WORKSPACES_DIR/$full_issue_number.code-workspace"

	if [ ! -f "$workspace_file" ]; then
		echo "Creating workspace file $workspace_file"

		echo "{" >"$workspace_file"
		echo '    "folders": [' >>"$workspace_file"
		echo "        {" >>"$workspace_file"
		echo "            \"name\": \"$current_dir\"," >>"$workspace_file"
		echo "            \"path\": \"../$current_dir\"" >>"$workspace_file"
		echo "        }" >>"$workspace_file"
		echo "    ]" >>"$workspace_file"
		echo "}" >>"$workspace_file"
	else
		echo "Adding $current_dir to workspace file $workspace_file"
		if ! grep -q "\"path\": \"../$current_dir\"" "$workspace_file"; then
		# TODO test this
			# echo "        {" >>"$workspace_file"
			# echo "            \"name\": \"$current_dir\"," >>"$workspace_file"
			# echo "            \"path\": \"../$current_dir\"" >>"$workspace_file"
			# echo "        }," >>"$workspace_file"
		else
			echo "Directory already in workspace file"
		fi
	fi
}

# 1. Creates a new branch with the given param as name
# 2. Links the workspace in the directory for the issue in the workspaces dir,
# 	creating the dir if it doesn't exist
# 3. Adds the linked directory to the VS Code workspace file ($WORKSPACES_DIR/VERBU-$1.code-workspace), creating it if it doesn't exist
#
# @param $1: issue number ($ISSUE_NUMBER)
# @param $2: branch name (appended to 'feature/VERBU-$ISSUE_NUMBER')
#
# Switches:
# 	--open - open the workspace in VS Code
# 	--no-ws-file - skip workspace file creation
issue_branch() {
	# Check for 2 parameters
	if [ $# -lt 2 ]; then
		echo "Usage: issue_branch <issue_number> <branch_name> [--open] [--no-ws-file]"
		echo
		echo "Example: issue_branch 1234 'My new feature' --open"
		echo "  This will create a new branch named feature/VERBU-1234_My-new-feature"
		echo "  and link the workspace in $WORKSPACES_DIR/VERBU-1234.code-workspace"
		echo "  then open it in VS Code"
		echo
		return 1
	fi

	# Issue number is always the first parameter
	issue_number="$1"
	branch_name="$2"

	shift 2

	#  Parse arguments
	open=false
	no_ws_file=false

	for param in "$@"; do
		case "$param" in
		--open)
			open=true
			shift
			;;
		--no-ws-file)
			no_ws_file=true
			shift
			;;
		esac
	done

	full_issue_number="VERBU-$issue_number"

	# Convert spaces in branch name to hyphens
	branch_name=$(echo "$branch_name" | tr ' ' '-')

	# Create the branch
	branch_name="feature/${full_issue_number}_${branch_name}"
	echo "Creating branch $branch_name"
	git checkout -b "$branch_name"

	# Create the workspace directory if it doesn't exist
	workspace_dir="$WORKSPACES_DIR/$full_issue_number"
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

	if [ "$no_ws_file" = false ]; then
		workspace_file "$full_issue_number" "$current_dir"
	fi

	# Open the workspace in VS Code
	if $open; then
		code "$WORKSPACES_DIR/$full_issue_number.code-workspace"
	fi
}

# Switch to all branches with the given issue number prefix
#
# @param $1: issue number
#
# Switches:
# 	--sync - sync before switching
# 	--sync-branch - sync the branch after switching
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
		cmd="checkout_branch_with_prefix $branch_prefix "
	fi

	if $sync_branch; then
		cmd="$cmd --pull"
	fi

	run_command_in_repos --no-output "$cmd"
}

# Switch to the master branch in all repos
#
# @param --no-pull - optional parameter to not pull changes after switching
switch_to_master() {
	# Parse arguments
	pull=true
	for param in "$@"; do
		case "$param" in
		--no-pull)
			pull=false
			shift
			;;
		esac
	done

	if [ "$pull" = false ]; then
		run_command_in_repos "git checkout master"
		return
	fi

	run_command_in_repos "git_sync master"
}

# 1. Checks out any branches that have the given issue number prefix
# 2. Pulls changes from the remote branch
# 3. Merges the remote branch into the local branch
# 4. Opens the relevant workspace in VS Code
#
# @param $1: issue number
open_issue() {
	# Check for parameter
	if [ -z "$1" ]; then
		echo "Usage: open_issue <issue_number>"
		return 1
	fi

	# Change to multi-repo_dir
	cd "$MULTI_REPO_DIR" || return 1

	# Issue number is always the first parameter
	issue_number="$1"

	# Remove the first parameter
	shift

	branch_prefix="feature/VERBU-$issue_number"

	# Run the command and capture the output
	cmd="checkout_branch_with_prefix $branch_prefix --pull --success-only"

	run_command_in_repos --no-output "$cmd"

	# Open the workspace in VS Code
	vs_code_cmd="code --new-window $WORKSPACES_DIR/VERBU-$issue_number.code-workspace"
	echo "$vs_code_cmd"
}

alias reset_storybook='rm -rf ./dist && rm -rf ./dist-stories && yb'
alias reset_next="rm -rf node_modules && rm -rf .next && yb"
alias reset_next_and_check="reset_next && yb && yt && yarn lint"