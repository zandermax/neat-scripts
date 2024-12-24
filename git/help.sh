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
# local -A my_examples=(
# 	["Prints the result"]="my_command --one --t"
# 	["Calls inner_function with value"]="my_command --two"
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
# 		Prints the result			my_command --one --t
# 		Calls inner_function with value		my_command --two
#
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

# Examples keys -> values == description -> command
	if [[ -n $examples ]]; then
		echo "Example usage:"
		for key value in ${(kv)${(P)examples}}; do
				echo "    $key    $value"
		done
		echo ""
	fi
}

my_function_help() {
	local my_var="my_value"
	local -A my_commands=(
		["--one|-1"]="Prints the result"
		["--two|-t"]="Calls inner_function with value"
		["--three|-3"]="Goes to the home directory"
	)

# Examples are description -> command
	local -A my_examples=(
		["Prints the result"]="my_command --one --t"
		["Calls inner_function with value"]="my_command --two"
		["Goes to the home directory"]="my_command --three"
	)

	echo "ONE"
	print_help "my_function" "This is my function" --examples=my_examples --switches=my_commands

	echo "TWO"
	print_help "my_function" "This is my function 2" --examples=my_examples

	echo "THREE"
	print_help "my_function" "This is my function 3" --switches=my_commands
}
