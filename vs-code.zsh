# Function to pull all repos in a VS Code workspace and merge origin/master into the active branch if different
merge_all_workspace_repos() {
	if [ -z "$1" ]; then
		echo "Usage: $0 <workspace_file>"
		return
	fi

	WORKSPACE_ROOT_DIR="$HOME/bu-repos-all/_workspaces_"
	WORKSPACE_PREFIX="VERBU-"
	WORKSPACE_FILE="$WORKSPACE_ROOT_DIR/$WORKSPACE_PREFIX$1".code-workspace

	printf "Workspace file: %s\n" "$WORKSPACE_FILE"

	if [ ! -f "$WORKSPACE_FILE" ]; then
		echo "The specified workspace file does not exist."
		return
	fi

	WORKSPACE_DIRS=$(jq -r '.folders[].path' "$WORKSPACE_FILE")
	cd "$WORKSPACE_ROOT_DIR" || return

	echo "$WORKSPACE_DIRS" | while IFS= read -r dir; do
		run_command_in_repos "git fetch origin master && git merge origin/master"
	done
}
