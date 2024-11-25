# Run command in all top-level git repos in a directory
# Available variables:
# - {repo_dir}: The directory of the repository
# @param --no-output: Suppress output
# @param $1: command to run
run_command_in_repos() {
	for param in "$@"; do
		case $param in
		--no-output)
			no_output=true
			shift
			;;
		esac
	done

	# Remaining param is the command to run
	local cmd="$1"

	# Check if a command is provided
	if [ -z "$cmd" ]; then
		echo "Usage: run_command_in_repos <command>"
		return 1
	fi

	# Iterate over all directories in the current directory
	for dir in */; do
		# Check if the directory contains a .git directory
		if [ -d "$dir/.git" ]; then
			#  Convert to absolute path
			repo_dir="$(cd "$dir" && pwd)"
			if [ "$no_output" != true ]; then
				printf "Running in %s\n" "$repo_dir"
			fi
			(
				cd "$repo_dir" || continue
				# Replace {repo_dir} in the command with the actual directory
				eval "${cmd//\{repo_dir\}/$repo_dir}"
			)
			if [ "$no_output" != true ]; then
				echo ""
			fi
		fi
	done
}

fetch_all() {
	run_command_in_repos "git fetch"
}

# @param $1: branch name
list_repos_not_on_branch() {
	# Check if a branch name is provided
	if [ -z "$1" ]; then
		echo "Usage: list_repos_not_on_branch <branch_name>"
		return 1
	fi

	local target_branch="$1"

	# Iterate over all directories in the current directory
	for dir in */; do
		# Check if the directory contains a .git directory
		if [ -d "$dir/.git" ]; then
			# Get the current branch name
			current_branch=$(cd "$dir" && git rev-parse --abbrev-ref HEAD)
			# Check if the current branch is not the target branch
			if [ "$current_branch" != "$target_branch" ]; then
				echo "$dir is on branch $current_branch"
			fi
		fi
	done
}

# Pull all changes in all git repos in a directory
pull_all() {
	error_dirs=""
	updated_count=0
	declare -A not_on_master=()
	run_command_in_repos "git stash && git pull || echo 'Error in {repo_dir}' >> /tmp/error$$"
	if [ -n "$error_dirs" ]; then
		echo -e "Errors occurred in the following directories:\n$error_dirs"
	else
		echo "Git pull successful in all directories."
	fi
	echo "Repositories updated: $updated_count"
	rm -f /tmp/error$$
}
