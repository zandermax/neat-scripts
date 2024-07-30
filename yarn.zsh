# Pull all changes in all git repos in a directory
build-all-npm() {
	# Initialize an empty string to store directories with errors
	error_dirs=""
	# Loop through all subdirectories
	for d in *-npm-*/; do
		echo "Running yarn install and yarn build in $d"
		# Attempt to pull, redirecting errors to a temp file
		if ! (cd "$d" && yarn install && yarn build) 2>/tmp/error$$; then
			echo "Error in $d"
			# Append the directory and error message to the error_dirs string
			error_dirs+="$d: $(cat /tmp/error$$)\n"
		fi
	done

	# Check if there were any errors
	if [ -n "$error_dirs" ]; then
		echo -e "Errors occurred in the following directories:\n$error_dirs"
	else
		echo "Built all npm projects successfully"
	fi

	# Clean up the temporary error file
	rm -f /tmp/error$$
}
