# Pull all changes in all git repos in a directory
pull-and-build-all() {
	# Initialize an empty string to store directories with errors
	error_dirs=""
	# Loop through all subdirectories
	for d in */; do
		if [ -d "$d/.git" ]; then # Check if the directory is a Git repository
			if [ "$(cd "$d" && git rev-parse --abbrev-ref HEAD)" != "master" ]; then
				echo "Not on master branch in $d, skipping"
				continue
			fi
			echo "Pulling in $d"
			# Attempt to pull, redirecting errors to a temp file
			if ! (cd "$d" && git stash && git pull) 2>/tmp/error$$; then
				echo "Error in $d"
				# Append the directory and error message to the error_dirs string
				error_dirs+="$d: $(cat /tmp/error$$)\n"
			# if no errors, install and build
			else
				echo "Running yarn install and yarn build in $d"
				(cd "$d" && yarn install && yarn build)
			fi
		fi
	done

	# Check if there were any errors
	if [ -n "$error_dirs" ]; then
		echo -e "Errors occurred in the following directories:\n$error_dirs"
	else
		echo "Git pull successful in all directories."
	fi

	# Clean up the temporary error file
	rm -f /tmp/error$$
}
