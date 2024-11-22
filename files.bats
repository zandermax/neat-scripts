#!/usr/bin/env bats

# Test variables
regexp_header="Count +Directory"
regexp_lines="-+ -+"
regexp_count="[0-9]+ \.+ subdir[0-9]+"

setup() {
	TEST_BREW_PREFIX="$(brew --prefix)"
	load "${TEST_BREW_PREFIX}/lib/bats-support/load.bash"
	load "${TEST_BREW_PREFIX}/lib/bats-assert/load.bash"
	source ./files.zsh
}

# Example output from `create_test_files 1 3 5`:
# testdir/subdir1 with 1 file
# testdir/subdir2 with 3 files
# testdir/subdir3 with 5 files
create_test_files() {
	for i in $(seq 1 $#); do
		mkdir -p testdir/subdir$i

		for j in $(seq 1 ${!i}); do
			touch testdir/subdir$i/file$j.test
		done

	done
}

teardown() {
	rm -rf testdir
}

@test "count_files function exists" {
	# Verify that the count_files function is available
	type count_files >/dev/null
	#  Check that last command succeeded, using BATS test checks
	assert_success
}

@test "count_files should show correct output" {
	local num_dirs=3
	create_test_files 1 3 5
	cd testdir

	run count_files

	assert_output --regexp "$regexp_header"
	assert_output --regexp "$regexp_lines"

	for i in $(seq 1 $num_dirs); do
		assert_output --regexp "$regexp_count"
	done

	cd ..
}

# @test "count_files_of_type should count files of specific types" {
# 	# Create a temporary directory structure for testing
# 	mkdir -p testdir
# 	touch testdir/file1.txt
# 	touch testdir/file2.js
# 	touch testdir/file3.txt
# 	touch testdir/file4.js
# 	touch testdir/file5.sh

# 	run count_files_of_type "txt,js"
# 	[ "$status" -eq 0 ]
# 	[ "${lines[0]}" = "Count Extension" ]
# 	[ "${lines[1]}" = "2 txt" ]
# 	[ "${lines[2]}" = "2 js" ]

# 	# Clean up
# 	rm -rf testdir
# }

# @test "execute_in_dirs should execute a command in matching directories" {
# 	# Create a temporary directory structure for testing
# 	mkdir -p testdir1
# 	mkdir -p testdir2
# 	touch testdir1/file1.txt
# 	touch testdir2/file2.txt

# 	run execute_in_dirs "testdir*" "touch newfile.txt"
# 	[ "$status" -eq 0 ]
# 	[ -f testdir1/newfile.txt ]
# 	[ -f testdir2/newfile.txt ]

# 	# Clean up
# 	rm -rf testdir1 testdir2
# }
