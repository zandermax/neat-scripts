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

# # Creates a loading bar that is displayed at the bottom of the terminal
# #
# # @param $1 - the total number of steps in the loading process
# # @param $2 - the current step
# # @param --bar-length [length] - optional, the length of the loading bar (default 50)
# loading_bar() {
# 	local total_steps=$1
# 	local current_step=$2
# 	local bar_length=50
# 	local fill_char="#"
# 	local empty_char="."

# 	echo "$total_steps $current_step"

# 	# Parse optional arguments
# 	for param in "$@"; do
# 		case "$param" in
# 		--bar-length)
# 			shift
# 			bar_length=$1
# 			shift
# 			;;
# 		esac
# 	done

# 	# Calculate the percentage of completion
# 	local percentage=$((100 * current_step / total_steps))
# 	local num_fill_chars=$((percentage * bar_length / 100))
# 	local num_empty_chars=$((bar_length - num_fill_chars))

# 	# Create the loading bar
# 	local bar=$(printf "%${num_fill_chars}s" | tr ' ' "$fill_char")
# 	local empty=$(printf "%${num_empty_chars}s" | tr ' ' "$empty_char")

# 	# Print the loading bar on the last line, clearing anything there
# 	# tput cup $(tput lines) 0
# 	printf "\r[%s%s] %d%%" "$bar" "$empty" "$percentage"
# }

# Function to initialize the loading bar
#
# @param $1 the number of items to_process
init_loading_bar() {
	local num_to_process=$1

	# Save the current cursor position
	tput sc
	# Draw the initial loading bar
	loading_bar "$num_to_process" 0
}

# Function to draw the loading bar
loading_bar() {
	local total=$1
	local current=$2
	local width=10 # Width of the progress bar in characters

	# Calculate the percentage and the number of filled '#' characters
	local percent=$(((current * 100) / total))
	local filled=$(((current * width) / total))

	# Build the loading bar string
	local bar="["
	for ((i = 1; i <= width; i++)); do
		if ((i <= filled)); then
			bar+="#"
		else
			bar+="."
		fi
	done
	bar+="]"

	# Restore cursor to the saved position and draw the loading bar
	tput rc

	local loading_status="Loading...\n"
	local max_loading_message_length=$((${#loading_status} + 1))
	if ((current == total)); then
		loading_status="Done!"
		# Add spaces to clear the previous loading message
		local spaces=$((max_loading_message_length - ${#loading_status}))
		loading_status+="$(printf "%${spaces}s")"
	fi

	echo
	echo -ne "${bar} ${percent}% ${loading_status}"
	echo
}

# Function to simulate processing with a loading bar
run_cmd_with_loading_bar() {
	local to_process=("item1" "item2" "item3" "item4" "item5")
	local num_to_process=${#to_process[@]}
	local num_processed=0

	# Initialize the loading bar
	init_loading_bar "$num_to_process"

	# Iterate over the items to process
	for item in "${to_process[@]}"; do
		# Simulate the command output
		echo "Processing $item..."
		sleep 1 # Simulate a delay for the command

		# Update the loading bar
		num_processed=$((num_processed + 1))
		loading_bar "$num_to_process" "$num_processed"
	done
}
