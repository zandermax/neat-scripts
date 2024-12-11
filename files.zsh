#  Load dependencies if needed (usually only in tests)
#  Source ./output.zsh if create_headers command is not defined
if ! type create_headers &>/dev/null; then
	source ./output.zsh
fi

# Function to show counts of files per directory, with headers in output
count_files() {
	create_headers "Count" "Directory"
	find . -mindepth 2 -type f | cut -d/ -f2 | sort | uniq -c | sort -nr | 2_column_output
}

count_files_of_type() {
	local extensions="$1"
	local IFS=','

	# Convert comma-separated list to array
	read -r -A ext_array <<<"$extensions"

	# Build the grep pattern
	local pattern=""
	for ext in "${ext_array[@]}"; do
		if [ -n "$pattern" ]; then
			pattern="$pattern|"
		fi
		pattern="$pattern\.$ext$"
	done

	# Find and count files
	create_headers "Count" "Extension"
	find . -type f | grep -E "$pattern" | sed -e 's/.*\.//' | sort | uniq -c | sort -nr | 2_column_output
}

# Function to iterate over directories and execute a command
execute_in_dirs() {
	local pattern=$1
	local command=$2
	echo "Pattern: $pattern"
	echo "Command: $command"
	echo "ls -d $pattern"
	error_dirs=""
	# Use find to expand the pattern and iterate over matching directories
	result=$(ls -d $pattern)
	echo "Result: $result"
	ls -d "$pattern" | while read -r d; do
		echo "Executing in $d"
		if ! (cd "$d" && eval "$command") 2>/tmp/error$$; then
			log_error "$d" /tmp/error$$
		fi
		echo ""
	done

	if [ -n "$error_dirs" ]; then
		echo -e "Errors occurred in the following directories:\n$error_dirs"
	else
		echo "Operation completed successfully"
	fi

	rm -f /tmp/error$$
}

# Moves a directory to a new location and creates a symlink to the new location
mln() {
	if [ $# -ne 2 ]; then
		echo "Usage: mln <directory> <destination>"
		return 1
	fi

	local dir=$1
	local dest=$2

	if [ ! -d "$dir" ]; then
		echo "Error: Directory '$dir' does not exist."
		return 1
	fi

	mv "$dir" "$dest"
	ln -s "$dest/$(basename "$dir")" "$dir"
}
