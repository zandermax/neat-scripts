# Run command in all git repos in a directory with changes
# Parameters:
# $1: Command to run
run_command_in_repos() {
	local cmd="$1" # Command to run
	for d in */; do
		(
			cd "$d" && git status -s | grep -v ".DS_Store" >/dev/null
			if [ $? -eq 0 ]; then
				echo "In $d"
				eval "$cmd"
				echo ""
			fi
		)
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

# Shows all repos in a directory that have useful changes
alias rgits="run-git-command-in-dirs 'git status -s | grep -v \".DS_Store\"'"

# Commit all changes in all git repos in a directory, with the same
commit_all() {
	run_command_in_repos "git commit -m \"$1\""
}
