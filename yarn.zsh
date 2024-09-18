alias ybs="yarn install && yarn build && yarn start"
alias yb="yarn install && yarn build"
alias ybw="yb --watch"
alias ys="yarn start"
alias yt="yarn test"
alias yr="yarn run"

#  Special stuff
alias find-unused="rev-dep entry-points --exclude '**/pages/**' '**/*.spec.*' '*gulpfile*' '*.config.*' '*jest*' 'server.js'"
alias find-where-used="rev-dep resolve"

build_all_npm() {
	# Initialize an empty string to store directories with errors
	error_dirs=""
	# Loop through all subdirectories
	for d in *-npm-*/; do
		echo "Running yarn install and yarn build in $d"
		if [ -d "$d/node_modules" ]; then
			echo "Deleting node_modules in $d"
			rm -rf "$d/node_modules"
		fi
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

# Runs yarn clean, if that fails, cleans manually
yarn_clean() {
	if ! yarn clean; then
		echo "Cleaning manually"
		rm -rf node_modules
		rm -rf dist
		rm -rf dist-stories
		rm -rf .cache
		rm -rf .next
		rm -rf .yarn
		rm -f yarn.lock
	fi
}
