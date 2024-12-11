#  Check if testing library is installed
if ! type bats &>/dev/null; then
	printf "Bats not found, installing...."
	printf "\n\n"

	brew tap kaos/shell
	brew install bats-assert && brew install bats-file
fi

# Run all tests in all subdirectories, any file that ends with .bats
for file in $(find . -name "*.bats"); do
	echo "Running tests in $file"
	bats "$file"
done
