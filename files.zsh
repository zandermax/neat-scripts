# Function to show counts of files per directory, with headers in output
count-files() {
	create-headers "Count" "Directory"
	find . -mindepth 2 -type f | cut -d/ -f2 | sort | uniq -c | sort -nr | 2-column-output
}

count-files-of-type() {
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
	create-headers "Count" "Extension"
	find . -type f | grep -E "$pattern" | sed -e 's/.*\.//' | sort | uniq -c | sort -nr | 2-column-output
}
