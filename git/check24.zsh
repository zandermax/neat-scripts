stars="********************************************************************************"

push() {
	# Parse arguments
	allow_master=false
	while [ $# -gt 0 ]; do
		case "$1" in
		--allow-master)
			allow_master=true
			shift
			;;
		*)
			break
			;;
		esac
	done

	# Check if on master branch and quit with a warning unless --allow-master is set
	current_branch=$(git rev-parse --abbrev-ref HEAD)
	if [ "$current_branch" = "master" ] && [ "$allow_master" = false ]; then
		echo "$stars"
		echo "$stars"
		echo "Error: You are on the master branch. Set --allow-master=true to allow pushing changes."
		echo "$stars"
		echo "$stars"
		return 1
	fi

	# Check if there are any dependencies with '-verbu-' in package.json, which requires migration
	if grep -q '"[^"]*-verbu-[^"]*"' package.json; then
		echo "$stars"
		echo "$stars"
		echo "Warning: A dependency with '-verbu-' was found in package.json."
		echo "Do not forget to run the migration script!"
		echo "$stars"
		echo "$stars"
	fi

	# Check if there is an upstream branch being tracked
	if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
		echo "No upstream branch found. Setting upstream to origin/$current_branch."
		git push --set-upstream origin "$current_branch" "$@"
	else
		# Run git push and append any other arguments
		git push "$@"
	fi
}
