#!/bin/zsh
parse_switches() {
    local -A cmd_map
    cmd_map=("${(@Pkv)1}")
    shift

    while [ "$1" != "" ]; do
			local found=0
			for key in "${(@k)cmd_map}"; do
				for subkey in ${(s:|:)key}; do
					if [[ "$1" == "$subkey" || "$1" == "$subkey="* ]]; then
						found=1
						if [[ "$1" == *=* ]]; then
								local value="${1#*=}"
								eval "${cmd_map[$key]} \"$value\""
						else
								eval "${cmd_map[$key]}"
						fi
						break 2
					fi
				done
			done
			if [[ $found -eq 0 ]]; then
				echo "Invalid option: $1"
			fi
			shift
    done
}

my_function() {
    local my_var="my_value"
    local -A my_commands=(
      ["--one|-1"]="printf 'result %s\n' $my_var"
      ["--two|-t"]="inner_function"
      ["--three|-3"]="cd ~"
    )
    parse_switches my_commands "$@"
}

another_function() {
    local -A another_commands=(
			["--one"]="echo 'one'"
			["-1"]="echo 'one'"
			["--two"]="inner_function"
			["-t"]="inner_function"
			["--three"]="ps -aux"
			["-3"]="ps -aux"
    )
    parse_switches another_commands "$@"
}

inner_function() {
    echo "Inner function called with value: $1"
}

# Example usage:
# my_function --one --two=value_for_two --three
# another_function --one --two=another_value --three
