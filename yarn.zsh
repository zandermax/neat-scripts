alias ybs="yarn install && yarn build && yarn start"
alias yb="yarn install && yarn build"
alias ys="yarn start"
alias yt="yarn test"

build-all-npm() {
	# Initialize an empty string to store directories with errors
	error_dirs=""
	# Loop through all subdirectories
	for d in *-npm-*/; do
		echo "Running yarn install and yarn build in $d"
		# Redirect errors to a temp file
		if ! (cd "$d" && yb) 2>/tmp/error$$; then
			echo "Error in $d"
			# Append the directory and error message to the error_dirs string
			error_dirs+="$d: $(cat /tmp/error$$)\n"
		fi
		echo ""
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
