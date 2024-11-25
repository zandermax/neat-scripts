# Function to format output of 2 columns with dots between the values
2_column_output() {
	awk '{
				# Calculate the number of dots needed
				dots = 30 - 1 - length($1)
				# Print the first column, dots, and second column
				printf "%s ", $1
				for (i = 0; i < dots; i++) printf "."
				printf " %s\n", $2
		}'
}

create_headers() {
	max_length=30
	printf "\n"
	# Print all headers
	for header in "$@"; do
		printf "%-${max_length}s " "$header"
	done
	printf "\n"

	# For each header except the last, print 30 dashes
	for ((i = 0; i < ${#@} - 1; i++)); do
		for ((j = 0; j < $max_length; j++)); do
			printf "-"
		done
		printf " "
	done
	# Print the remaining dashes to reach the end of the line (max_length - length of last header)
	last_header_length=${#header}
	for ((i = 0; i < $last_header_length + 1; i++)); do
		printf "-"
	done

	printf "\n"
}

show_loading_animation() {
	local pid=$1
	local delay=0.1
	local spinstr='|/-\'
	while [ "$(ps a | awk '{print $1}' | grep "$pid")" ]; do
		local temp=${spinstr#?}
		printf " [%c]  " "$spinstr"
		local spinstr=$temp${spinstr%"$temp"}
		printf "\b\b\b\b\b\b"
		sleep $delay
	done
	printf "    \b\b\b\b"
}
