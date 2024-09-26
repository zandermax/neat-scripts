# Run command in all top-level git repos in a directory
# Parameters:
# $1: Command to run
# Available variables:
# - {repo_dir}: The directory of the repository
run_command_in_repos() {
	local cmd="$1" # Command to run

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
			printf "Running in %s\n" "$repo_dir"
			(
				cd "$repo_dir" || continue
				# Replace {repo_dir} in the command with the actual directory
				eval "${cmd//\{repo_dir\}/$repo_dir}"
			)
		fi
	done
}

fetch_all() {
	for d in */; do
		if [ -d "$d/.git" ]; then
			echo "Fetching in $d"
			(cd "$d" && git fetch)
		fi
	done
}

# Pull all changes in all git repos in a directory
pull_all() {
	# Initialize variables to store directories with errors and updated repos
	error_dirs=""
	updated_count=0
	declare -A not_on_master=()

	# Loop through all subdirectories
	for d in */; do
		if [ -d "$d/.git" ]; then # Check if the directory is a Git repository
			# Get the current branch name
			current_branch=$(cd "$d" && git rev-parse --abbrev-ref HEAD)
			# Check if on master branch
			if [ "$current_branch" != "master" ]; then
				echo "Not on master branch in $d, skipping"
				not_on_master["$d"]="$current_branch"
				continue
			fi
			# Stash any changes, attempt to pull, redirecting errors to a temp file
			echo "Pulling in $d"
			if ! (cd "$d" && git stash && git pull) 2>/tmp/error$$; then
				echo "Error in $d"
				# Append the directory and error message to the error_dirs string
				error_dirs+="$d: $(cat /tmp/error$$)\n"
			else
				updated_count=$((updated_count + 1))
			fi
			echo ""
		fi
	done

	# Prettified output
	echo "==================== Summary ===================="
	echo "Repositories updated: $updated_count"
	if [ ${#not_on_master[@]} -ne 0 ]; then
		echo "Repositories not on master branch:"
		for repo in "${!not_on_master[@]}"; do
			echo "  - $repo (branch: ${not_on_master[$repo]})"
		done
	fi
	if [ -n "$error_dirs" ]; then
		echo -e "Errors occurred in the following directories:\n$error_dirs"
	else
		echo "Git pull successful in all directories."
	fi
	echo "================================================="

	# Clean up the temporary error file
	rm -f /tmp/error$$
}
