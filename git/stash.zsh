# Stashes files that are skipped with --assume-unchanged and --skip-worktree, then runs a given command
# Finally, runs git stash pop to restore the stashed files
with_skipped() {
	# Check if a command is provided
	if [ $# -eq 0 ]; then
		printf "Stashes files that are skipped with --assume-unchanged and --skip-worktree, then runs a given command\n"
		printf "Finally, runs git stash pop to restore the stashed files\n"
		return
	fi

	# Get the list of files with --assume-unchanged
	assume_unchanged_files=$(git ls-files -v | grep '^h' | awk '{print $2}')
	# Get the list of files with --skip-worktree
	skip_worktree_files=$(git ls-files -v | grep '^S' | awk '{print $2}')

	# Temporarily unset the flags
	for file in $assume_unchanged_files; do
		printf "Unsetting --assume-unchanged for %s\n" "$file"
		git update-index --no-assume-unchanged "$file"
	done
	for file in $skip_worktree_files; do
		printf "Unsetting --skip-worktree for %s\n" "$file"
		git update-index --no-skip-worktree "$file"
	done

	# Stash all changes, including the previously skipped files
	git stash push --include-untracked --keep-index

	# Run the provided command
	"$@"

	# Restore the stashed files
	git stash pop

	# Reapply the flags
	for file in $assume_unchanged_files; do
		git update-index --assume-unchanged "$file"
	done
	for file in $skip_worktree_files; do
		git update-index --skip-worktree "$file"
	done
}
