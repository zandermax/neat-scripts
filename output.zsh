stars="********************************************************************************"

# Outputs in 2 columns, separated by dots of a specified width
# @param --width [width] - optional, the width of the columns (default 30)
2_column_output() {
	width=30

	# Parse optional width parameter
	while [[ "$1" =~ ^--width ]]; do
		case "$1" in
		--width)
			shift
			width=$1
			shift
			;;
		esac
	done

	# Read input from pipe
	while IFS= read -r line; do
		if [[ "$line" == *"__"* ]]; then
			IFS="__" read -r col1 col2 <<<"$line"
		else
			IFS=" " read -r col1 col2 <<<"$line"
		fi

		# Remove any leading underscore from col2
		col2=${col2#_}

		# Calculate the number of dots needed
		dots=$((width - ${#col1} - ${#col2}))
		if ((dots < 0)); then
			dots=0
		fi

		# Generate dots
		dot_str=$(printf "%${dots}s" | tr ' ' '.')

		# Print the formatted output
		printf "%s %s %s\n" "$col1" "$dot_str" "$col2"
	done
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

# Prints the help message for a command
# @param $1 - the command name
# @param $2 - the description of the command
# @param --switch [switch values] [switch description] - optional, switch values and description
# @param --example [example command] [example description] - optional, example command and description
#
#
# Example:
# print_help "my_command" "This is my command" --switch "-a, --all" "Do all the things" --example "my_command -a \"value for -a\"" --example "my_command --all \"value for --all\""
#
# Example output:
# 	my_command - This is my command
#
# 	Switches:
# 		-a, --all				Do all the things
#
# 	Example usage:
# 		my_command -a "value for -a"
# 		my_command --all "value for --all"
print_help() {
	# The first argument is the command name
	local command_name=$1
	shift

	# The second argument is the description
	local description=$1
	shift

	# Initialize the arrays for the switches and examples
	local switches=()
	local examples=()

	# Parse the rest of the arguments
	while [ $# -gt 0 ]; do
		case $1 in
		--switch)
			# Add dots between the values and the description, so that the full line length is 80 characters
			switch_values=($2)
			# Description (may have spaces)
			switch_description="$3"

			switches+="${switch_values[@]}"__"$switch_description"
			shift 3
			;;
		--example)
			# Add the example command and description to the examples array
			examples+=("$2")
			shift 2
			;;
		esac
	done

	# Print the command name and description
	printf "%s - %s\n\n" "$command_name" "$description"

	# Print the switches if there are any
	if [ ${#switches[@]} -gt 0 ]; then
		printf "Switches:\n"
		for switch in "${switches[@]}"; do
			printf "\t%s\n" "$switch" | 2_column_output --width 80
		done
		printf "\n"
	fi

	# Print the examples if there are any
	if [ ${#examples[@]} -gt 0 ]; then
		printf "Example usage:\n"
		for example in "${examples[@]}"; do
			# Include any quotes in the example command
			printf "\t%s\n" "$example"
		done
		printf "\n"
	fi
}

# Shows a loading spinner while a command is run
# @param $1 - the command to run
run_with_loading_animation() {
	local command="$*"
	local delay=0.1
	local spin_string='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
	# Run the command in a subshell with job control messages suppressed
	(
		eval "$command"
	) &>/dev/null &
	local cmd_pid=$!
	# Show the loading animation while the command is running
	while kill -0 "$cmd_pid" 2>/dev/null; do
		for ((i = 0; i < ${#spin_string}; i++)); do
			printf "\r[%s] " "${spin_string:$i:1}"
			sleep $delay
		done
	done
	# Wait for the command to finish
	wait "$cmd_pid"
	# Clear the spinner
	printf "\r    \r"
}
