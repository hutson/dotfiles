#!/usr/bin/env bats

# Dynamic tests for the study question selector. Fixtures are built in a temporary directory
# and removed after each test, so the suite is offline, non-destructive, and repeatable.

bats_require_minimum_version 1.5.0

setup() {
	helper="${BATS_TEST_DIRNAME}/../.config/opencode/scripts/study-select.sh"
	fixtures="$(mktemp -d "${BATS_TMPDIR}/study-select.XXXXXXXXXX")"
}

teardown() {
	rm -rf "${fixtures}"
}

# Appends a section with `count` questions of one difficulty to `path`, mirroring the format
# the selector parses: a `## ` heading, then `**Question:**`, `**Difficulty:**`, and `**Answer:**`.
skill_file() {
	local path=$1 section=$2 difficulty=$3 count=$4
	local i

	printf '\n## %s\n' "${section}" >> "${path}"
	for ((i = 1; i <= count; i++)); do
		printf '\n**Question:** %s question %s?\n\n**Difficulty:** %s\n\n**Answer:** Answer %s for %s.\n' \
			"${section}" "${i}" "${difficulty}" "${i}" "${section}" >> "${path}"
	done
}

# Joins the stdout lines captured by the preceding `run --separate-stderr` call, keeping the
# pool-exhaustion warnings on stderr out of the parsed selection.
selections() {
	printf '%s\n' "${lines[@]}"
}

@test "a multi-file run reports line bounds within each file" {
	skill_file "${fixtures}/first.md" "First Section" Easy 2
	skill_file "${fixtures}/second.md" "Second Section" Medium 2

	run --separate-stderr bash "${helper}" --count 999 "${fixtures}/first.md" "${fixtures}/second.md"
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 4 ]

	# A startline counted across all files would land past the end of the second file, which
	# is how the selector used to hand the study agent offsets its reads could not satisfy.
	expected_start="$(grep -n '^\*\*Question:\*\* Second Section question 1?' "${fixtures}/second.md" | cut -d: -f1)"
	actual_start="$(selections | awk -F'|' '$2 ~ /second\.md/ {print $3}' | sort -n | head -1)"
	[ "${actual_start}" -eq "${expected_start}" ]

	# The open question of a file must close at that file's last line (exclusive), not at the
	# line where the next file happens to start.
	first_file_lines="$(wc -l < "${fixtures}/first.md")"
	last_end="$(selections | awk -F'|' '$2 ~ /first\.md/ {print $4}' | sort -n | tail -1)"
	[ "${last_end}" -eq "$((first_file_lines + 1))" ]
}

@test "a full block selects three easy, two medium, and one hard question" {
	skill_file "${fixtures}/pool.md" "Wide Pool" Easy 6
	skill_file "${fixtures}/pool.md" "Wide Pool" Medium 4
	skill_file "${fixtures}/pool.md" "Wide Pool" Hard 4

	run --separate-stderr bash "${helper}" --count 6 "${fixtures}/pool.md"
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 6 ]

	easy="$(selections | awk -F'|' '$1 == "Easy"' | wc -l)"
	medium="$(selections | awk -F'|' '$1 == "Medium"' | wc -l)"
	hard="$(selections | awk -F'|' '$1 == "Hard"' | wc -l)"
	[ "${easy}" -eq 3 ]
	[ "${medium}" -eq 2 ]
	[ "${hard}" -eq 1 ]
}

@test "selecting more than one block never repeats a question" {
	skill_file "${fixtures}/pool.md" "Deep Pool" Easy 6
	skill_file "${fixtures}/pool.md" "Deep Pool" Medium 4
	skill_file "${fixtures}/pool.md" "Deep Pool" Hard 4

	run --separate-stderr bash "${helper}" --count 12 "${fixtures}/pool.md"
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 12 ]

	# Every selection must come from a pool that shrank, so a two-block run yields twelve
	# distinct questions rather than six questions printed twice.
	unique="$(selections | sort -u | wc -l)"
	[ "${unique}" -eq 12 ]
}

@test "an exhausted difficulty pool warns, substitutes, and stays duplicate-free" {
	skill_file "${fixtures}/thin.md" "Thin Pool" Easy 2
	skill_file "${fixtures}/thin.md" "Thin Pool" Medium 2
	skill_file "${fixtures}/thin.md" "Thin Pool" Hard 2

	run --separate-stderr bash "${helper}" --count 6 "${fixtures}/thin.md"
	[ "$status" -eq 0 ]

	# Three easy questions are wanted but only two exist, so the shortcoming must be reported.
	[[ "${stderr}" == *"pool exhausted"* ]]

	# The remaining slot is filled from the union of leftovers, which may only hold questions
	# that are not already in the block.
	[ "${#lines[@]}" -eq 6 ]
	unique="$(selections | sort -u | wc -l)"
	[ "${unique}" -eq 6 ]
}

@test "an excluded question id is not selected" {
	skill_file "${fixtures}/skip.md" "Skips" Easy 3

	run --separate-stderr bash "${helper}" --count 999 "${fixtures}/skip.md"
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 3 ]
	excluded="$(selections | awk -F'|' 'NR == 1 {print $2 ":" $3}')"

	run --separate-stderr bash "${helper}" --count 999 --exclude "${excluded}" "${fixtures}/skip.md"
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 2 ]
	[[ "$(selections)" != *"${excluded}"* ]]
}

@test "a block without a parseable difficulty is dropped, not inherited" {
	skill_file "${fixtures}/broken.md" "Broken" Easy 1
	printf '\n**Question:** Broken question without a difficulty?\n\n**Difficulty:** Trivial\n\n**Answer:** This difficulty is not one of Easy, Medium, or Hard.\n' >> "${fixtures}/broken.md"
	skill_file "${fixtures}/broken.md" "Broken" Medium 1

	run --separate-stderr bash "${helper}" --count 999 "${fixtures}/broken.md"
	[ "$status" -eq 0 ]

	# A question that keeps no difficulty of its own must not be handed the difficulty left
	# over from the previous block, which would mislabel what the study agent asks.
	[ "${#lines[@]}" -eq 2 ]
	easy="$(selections | awk -F'|' '$1 == "Easy"' | wc -l)"
	medium="$(selections | awk -F'|' '$1 == "Medium"' | wc -l)"
	[ "${easy}" -eq 1 ]
	[ "${medium}" -eq 1 ]
}
