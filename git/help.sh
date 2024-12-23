#!/bin/zsh

# Prints the help message for a command
# @param $1 - the command name
# @param $2 - the description of the command
# @param --switches=[switch value]->[switch description] - (optional) switch values and description, as an associative array
# @param --examples=[example command]->[example description] - optional, example commands and descriptions
#
#
# Example:
#
# local -A my_switches=(
# 	["--one|-1"]="Prints the result"
#		["--two|-t"]="Calls inner_function with value"
# 	["--three|-3"]="Goes to the home directory"
# )
# local my_examples=(
# 	"my_command --one --t"
# )
# print_help "my_command" "This is my command" --examples=my_examples --switches=my_switches
#
# ----------------
# Example output:
# ----------------
# 	my_command - This is my command
#
# 	Switches:
# 		-a, --all (optional)				Do all the things
#
# 	Example usage:
# 		my_command -a="value for -a"
# 		my_command --all="value for --all"
print_help() {
	local command_name=$1
	local description=$2
	local switches examples

	# Parse optional arguments
	for arg in "$@"; do
		case $arg in
			--switches=*)
					switches="${arg#*=}"
					;;
			--examples=*)
					examples="${arg#*=}"
					;;
		esac
	done

	echo "$command_name - $description"
	echo ""

	if [[ -n $switches ]]; then
		echo "Switches:"
		for key value in ${(kv)${(P)switches}}; do
			echo "    $key    $value"
		done
		echo ""
	fi

	if [[ -n $examples ]]; then
		echo "Example usage:"
		for example in ${(P)examples}; do
			echo "    $example"
		done
		echo ""
	fi
}

# ...existing code...

my_function_help() {
	local my_var="my_value"
	local -A my_commands=(
		["--one|-1"]="Prints the result"
		["--two|-t"]="Calls inner_function with value"
		["--three|-3"]="Goes to the home directory"
	)

	local examples=(
		"my_function --one --two=value_for_two --three"
		"my_function -1 --two=another_value --three"
	)

	print_help "my_function" "This is my function" --examples=examples --switches=my_commands
}
