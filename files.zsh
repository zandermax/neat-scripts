# Function to show counts of files per directory, with headers in output
count-files() {
	printf "\n"
	printf "%-30s %s\n" "File Count" "Directory"
	printf "%-30s %s\n" "---------" "----------"
	find . -mindepth 2 -type f | cut -d/ -f2 | sort | uniq -c | sort -nr | awk '{
				# Calculate the number of dots needed
				dots = 30 - 1 - length($1)
				# Print the file count, dots, and directory name
				printf "%s ", $1
				for (i = 0; i < dots; i++) printf "."
				printf " %s/\n", $2
		}'
}
