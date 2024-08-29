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
	# Initialize an empty string to store directories with errors
	error_dirs=""
	# Loop through all subdirectories
	for d in */; do
		if [ -d "$d/.git" ]; then # Check if the directory is a Git repository
			# check if on master branch
			if [ "$(cd "$d" && git rev-parse --abbrev-ref HEAD)" != "master" ]; then
				echo "Not on master branch in $d, skipping"
				continue
			fi
			# Stash any changes, attempt to pull, redirecting errors to a temp file
			echo "Pulling in $d"
			if ! (cd "$d" && git stash && git pull) 2>/tmp/error$$; then
				echo "Error in $d"
				# Append the directory and error message to the error_dirs string
				error_dirs+="$d: $(cat /tmp/error$$)\n"
			fi
			echo ""
		fi
	done

	# Check if there were any errors
	if [ -n "$error_dirs" ]; then
		echo -e "Errors occurred in the following directories:\n$error_dirs"
	else
		echo "Git pull successful in all directories."
		echo ""
	fi

	# Clean up the temporary error file
	rm -f /tmp/error$$
}
