# Function to pull all repos in a VS Code workspace and merge origin/master into the active branch if different
merge_all_workspace_repos() {
	# Check if the workspace file path is provided
	if [ -z "$1" ]; then
		echo "Usage: $0 <workspace_file>"
		return
	fi

	# Path to the root directory of all workspaces
	WORKSPACE_ROOT_DIR="$HOME/bu-repos-all/_workspaces_"
	# Prefix for the workspace file name (currently based on who I am working for)
	WORKSPACE_PREFIX="VERBU-"

	# Path to the VS Code workspace file
	WORKSPACE_FILE="$WORKSPACE_ROOT_DIR/$WORKSPACE_PREFIX$1".code-workspace

	printf "Workspace file: %s\n" "$WORKSPACE_FILE"

	# Check if the workspace file exists
	if [ ! -f "$WORKSPACE_FILE" ]; then
		echo "The specified workspace file does not exist."
		return
	fi

	# Extract directories from the workspace file
	WORKSPACE_DIRS=$(jq -r '.folders[].path' "$WORKSPACE_FILE")

	# Directories are relative to the workspace file, so we need to resolve them
	cd "$WORKSPACE_ROOT_DIR" || return

	# Iterate through each directory in the workspace
	echo "$WORKSPACE_DIRS" | while IFS= read -r dir; do
		if [ -d "$dir/.git" ]; then
			echo "Processing repo: $dir"
			cd "$dir" || continue

			# Get the current branch name
			current_branch=$(git rev-parse --abbrev-ref HEAD)

			# Pull the latest changes from the remote master branch
			echo "Pulling latest changes from origin/master"
			git fetch origin master

			# Merge origin/master into the current branch if it is not master
			if [ "$current_branch" != "master" ]; then
				echo "Merging origin/master into $current_branch"
				git merge origin/master
			else
				echo "Already on master branch, no merge needed"
			fi

			cd - || exit
		else
			echo "Skipping non-repo directory: $dir"
		fi
		echo
	done
}
