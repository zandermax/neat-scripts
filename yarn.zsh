alias ybs="yarn install && yarn build && yarn start"
alias yb="yarn install && yarn build"
alias ybw="yb --watch"
alias yl="yarn lint"
alias ys="yarn start"
alias yt="yarn test"
alias yr="yarn run"

# Special stuff
alias find-unused="rev-dep entry-points --exclude '**/pages/**' '**/*.spec.*' '*gulpfile*' '*.config.*' '*jest*' 'server.js'"
alias find-where-used="rev-dep resolve"

# Function to handle error logging
log_error() {
	local dir=$1
	local error_file=$2
	echo "Error in $dir"
	error_dirs+="$dir: $(cat "$error_file")\n"
}

build_all_npm() {
	execute_in_dirs "*-npm-*/" "yb"
	echo "Built all npm packages"
	echo
}

link_all_npm() {
	execute_in_dirs "*-npm-*/" "yarn link"
}

unlink_all_npm() {
	execute_in_dirs "\*-npm-\*/" "yarn unlink"
	echo "Unlinked all npm packages"
	echo
}

get_all_linked() {
	execute_in_dirs "*-npm-*/" "yarn list --depth=0"
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
	else
		yarn clean
	fi
}

alias yarn-reset="yarn clean && yb && yl && yt"
