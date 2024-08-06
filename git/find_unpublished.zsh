# Finds all branches with unpushed or unpublished commits in all subdirectories
# Parameters:
# $1: Branch prefix to search for (optional)
# Options:
# --publish: Publishes all unpublished branches found
find_unpushed() {
	branch_prefix=""
	publish_unpublished=false

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case $1 in
		--publish)
			publish_unpublished=true
			shift
			;;
		*)
			branch_prefix=$1
			shift
			;;
		esac
	done

	found_dirs_unpublished=""
	found_dirs_uncommitted=""
	published_dirs=""
	error_dirs=""

	# Loop through each subdirectory
	for dir in */; do
		if [ -d "$dir/.git" ]; then
			echo
			echo "Checking $dir"
			cd "$dir" || continue

			if [ -n "$branch_prefix" ]; then
				# Check if any branch starting with the given prefix has unpushed or unpublished commits
				for branch in $(git branch --list "$branch_prefix*"); do
					# Filter out the case where branch is exactly '*'
					if [ "$branch" != "*" ]; then
						echo "Checking branch $branch"
						if git status -uno | grep -q "Your branch is ahead of"; then
							echo "Branch '$branch' with unpushed commits found in: $dir"
							found_dirs_uncommitted+="$dir\n"
							break
						elif ! git show-ref --quiet --verify "refs/remotes/origin/$branch"; then
							echo "Branch '$branch' is unpublished in: $dir"
							found_dirs_unpublished+="$dir\n"
							if [ "$publish_unpublished" = true ]; then
								echo "Publishing branch '$branch' to remote in: $dir"
								if git push -u origin "$branch"; then
									published_dirs+="$dir\n"
								else
									error_dirs+="$dir\n"
								fi
							fi
							break
						fi
					fi
				done
			else
				# Check if the current branch has unpushed or unpublished commits
				if git status -uno | grep -q "Your branch is ahead of"; then
					echo "Branch with unpushed commits found in: $dir"
					found_dirs_uncommitted+="$dir\n"
				elif ! git show-ref --quiet --verify "refs/remotes/origin/$(git rev-parse --abbrev-ref HEAD)"; then
					echo "Branch is unpublished in: $dir"
					found_dirs_unpublished+="$dir\n"
					if [ "$publish_unpublished" = true ]; then
						echo "Publishing branch to remote in: $dir"
						if git push -u origin "$(git rev-parse --abbrev-ref HEAD)"; then
							published_dirs+="$dir\n"
						else
							error_dirs+="$dir\n"
						fi
					fi
				fi
			fi

			cd - >/dev/null || exit
		fi
	done

	echo "Finished checking all directories."
	echo "---------------------------------"

	# Output all directories where branches with unpushed or unpublished commits were found
	# Define color codes
	RED='\033[0;31m'
	GREEN='\033[0;32m'
	YELLOW='\033[0;33m'
	BLUE='\033[0;34m'
	NC='\033[0m' # No Color

	# Define emojis
	INFO_EMOJI="ℹ️"
	SUCCESS_EMOJI="✅"
	ERROR_EMOJI="❗️"
	echo
	if [ -n "$found_dirs_uncommitted" ]; then
		echo -e "${YELLOW}${INFO_EMOJI} Branches with unpushed commits were found in the following directories:${NC}\n$found_dirs_uncommitted"
	fi
	if [ -n "$found_dirs_unpublished" ]; then
		echo -e "${BLUE}${INFO_EMOJI} Branches with unpublished commits were found in the following directories:${NC}\n$found_dirs_unpublished"
	fi
	if [ -n "$published_dirs" ]; then
		echo -e "${GREEN}${SUCCESS_EMOJI} Branches were successfully published in the following directories:${NC}\n$published_dirs"
	fi
	if [ -n "$error_dirs" ]; then
		echo -e "${RED}${ERROR_EMOJI} Errors occurred while publishing branches in the following directories:${NC}\n$error_dirs"
	fi
	if [ -z "$found_dirs_uncommitted" ] && [ -z "$found_dirs_unpublished" ]; then
		echo -e "${GREEN}${SUCCESS_EMOJI} No branches with unpushed or unpublished commits were found in any directories.${NC}"
	fi
}
