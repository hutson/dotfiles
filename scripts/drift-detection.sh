#!/usr/bin/env bash

# Compares shared developer-tooling configuration across projects in the current
# directory in three classes: whole-file comparisons (.devcontainer/devcontainer.json,
# .gitattributes, license.md) against every project; region comparisons (the shared
# scaffold of Containerfile and .tools/test.sh, and the readme.md `## Development`
# section) and invariant checks against the projects in `projects_in_scope` only.
# Report tool: always exits 0, even when drift is detected.

set -o errexit -o nounset -o noglob -o pipefail
readonly _trace_start_time_us=${EPOCHREALTIME//./}
PS4='[DEBUGLEVEL:${SHLVL} SUBSHELL:${BASH_SUBSHELL} LINE:${LINENO} DIFF:$(us=$(( ${EPOCHREALTIME//./} - _trace_start_time_us )); ms=$(( us / 1000 )); printf "%d.%03d" $((ms / 1000)) $((ms % 1000)) )s SOURCE:${BASH_SOURCE}] '

workspace_dir="$(pwd)"

# Projects whose shared regions and invariants are checked. The Go-family siblings
# (gardening, semantic-tag) keep legacy script headers and tool layouts and are
# deliberately out of scope until they adopt the current conventions.
projects=()
readonly projects_in_scope=(dotfiles hyper-expanse infrastructure)
readonly reference=dotfiles
readonly cross_check_a=semantic-tag
readonly cross_check_b=gardening
readonly shared_files=(
	.devcontainer/devcontainer.json
	.gitattributes
	license.md
)
readonly shared_regions=(
	.devcontainer/Containerfile
	.tools/test.sh
	readme.md
)

diff_count=0
matched_count=0
missing_count=0
invariant_failures=0

discover_projects() {
	while IFS= read -r -d '' project_path; do
		projects+=("$(basename "${project_path}")")
	done < <(find "${workspace_dir}" -mindepth 1 -maxdepth 1 -type d -not -name '.git' -print0 | sort -z)
}

print_header() {
	local header="${1}"
	printf '\n==================== %s ====================\n' "${header}"
}

# Returns the portion of a file that is expected to be identical across projects.
shared_content() {
	local path="${1}"
	case "$(basename "${path}")" in
	Containerfile)
		# Everything outside the repo-specific `---` block: the shared prefix
		# through the first marker, plus the trailing USER root/hadolint section.
		sed -n '1,/^# ---$/p' "${path}"
		sed -n '/^# NOTE: The container/,$p' "${path}"
		;;
	test.sh)
		# The shared preamble, from the shebang through the shellcheck section;
		# the project-specific checks that follow are expected to differ.
		awk '/^echo ".*shellcheck.*passed"$/ { print; exit } { print }' "${path}"
		;;
	readme.md)
		# The `## Development` section is the final section in every project;
		# everything above it is project-specific prose.
		sed -n '/^## Development/,$p' "${path}"
		;;
	*)
		cat "${path}"
		;;
	esac
}

report_projects_without_devcontainer() {
	local project
	for project in "${projects[@]}"; do
		if [ ! -d "${workspace_dir}/${project}/.devcontainer" ]; then
			print_header "${project}/.devcontainer"
			echo "SKIPPED: no .devcontainer directory"
		fi
	done
}

# Compares one repo-relative path against the reference project, for each of the
# projects passed as the remaining arguments.
compare_file_against_reference() {
	local file="${1}"
	shift
	local target_projects=("${@}")
	local reference_path="${workspace_dir}/${reference}/${file}"

	local project
	for project in "${target_projects[@]}"; do
		if [ "${project}" = "${reference}" ]; then
			continue
		fi

		local project_path="${workspace_dir}/${project}/${file}"

		print_header "${reference}/${file} vs ${project}/${file}"

		if [ ! -f "${reference_path}" ] && [ ! -f "${project_path}" ]; then
			echo "SKIPPED: both projects missing ${file}"
			continue
		fi

		if [ ! -f "${reference_path}" ]; then
			echo "MISSING: ${reference} has no ${file}"
			missing_count=$((missing_count + 1))
			continue
		fi

		if [ ! -f "${project_path}" ]; then
			echo "MISSING: ${project} has no ${file}"
			missing_count=$((missing_count + 1))
			continue
		fi

		if diff -q <(shared_content "${reference_path}") <(shared_content "${project_path}") >/dev/null 2>&1; then
			echo "IDENTICAL"
			matched_count=$((matched_count + 1))
		else
			# diff exits 1 when files differ; with errexit enabled, `|| true`
			# keeps the script alive so the summary counters can record the result.
			diff -u \
				--label "${reference}/${file}" \
				--label "${project}/${file}" \
				<(shared_content "${reference_path}") <(shared_content "${project_path}") || true
			diff_count=$((diff_count + 1))
		fi
	done
}

compare_cross_check() {
	local project_a="${1}"
	local project_b="${2}"

	print_header "${project_a} vs ${project_b} cross-check"

	local file
	for file in "${shared_files[@]}"; do
		local path_a="${workspace_dir}/${project_a}/${file}"
		local path_b="${workspace_dir}/${project_b}/${file}"

		echo
		echo "--- ${file} ---"

		if [ ! -f "${path_a}" ] && [ ! -f "${path_b}" ]; then
			echo "SKIPPED: both projects missing ${file}"
			continue
		fi

		if [ ! -f "${path_a}" ]; then
			echo "MISSING: ${project_a} has no ${file}"
			missing_count=$((missing_count + 1))
			continue
		fi

		if [ ! -f "${path_b}" ]; then
			echo "MISSING: ${project_b} has no ${file}"
			missing_count=$((missing_count + 1))
			continue
		fi

		if diff -q <(shared_content "${path_a}") <(shared_content "${path_b}") >/dev/null 2>&1; then
			echo "IDENTICAL"
			matched_count=$((matched_count + 1))
		else
			# diff exits 1 when files differ; with errexit enabled, `|| true`
			# keeps the script alive so the summary counters can record the result.
			diff -u \
				--label "${project_a}/${file}" \
				--label "${project_b}/${file}" \
				<(shared_content "${path_a}") <(shared_content "${path_b}") || true
			diff_count=$((diff_count + 1))
		fi
	done
}

require_file_present() {
	local path="${1}"
	local description="${2}"

	if [ -f "${path}" ]; then
		echo "✓ ${description}"
	else
		echo "✗ ${description}: file not found"
		invariant_failures=$((invariant_failures + 1))
	fi
}

require_in_file() {
	local path="${1}"
	local pattern="${2}"
	local description="${3}"

	if grep -qF -- "${pattern}" "${path}" 2>/dev/null; then
		echo "✓ ${description}"
	else
		echo "✗ ${description}"
		invariant_failures=$((invariant_failures + 1))
	fi
}

require_regex_in_file() {
	local path="${1}"
	local pattern="${2}"
	local description="${3}"

	if grep -Eq -- "${pattern}" "${path}" 2>/dev/null; then
		echo "✓ ${description}"
	else
		echo "✗ ${description}"
		invariant_failures=$((invariant_failures + 1))
	fi
}

require_pattern_count() {
	local path="${1}"
	local pattern="${2}"
	local expected="${3}"
	local description="${4}"

	local actual
	# `|| true` keeps a zero-match (grep exits 1) from tripping errexit.
	actual="$(grep -c -- "${pattern}" "${path}" 2>/dev/null || true)"

	if [ "${actual}" = "${expected}" ]; then
		echo "✓ ${description}"
	else
		echo "✗ ${description} (found ${actual}, expected ${expected})"
		invariant_failures=$((invariant_failures + 1))
	fi
}

check_project_invariants() {
	local project="${1}"
	local project_dir="${workspace_dir}/${project}"

	print_header "INVARIANTS ${project}"

	# File presence.
	require_file_present "${project_dir}/license.md" "${project}: license.md exists"
	require_file_present "${project_dir}/.gitignore" "${project}: .gitignore exists"

	# readme.md structure.
	local readme="${project_dir}/readme.md"
	require_in_file "${readme}" "## Design Decisions" "readme.md has a Design Decisions section"
	require_in_file "${readme}" "## Development" "readme.md has a Development section"
	require_in_file "${readme}" ".tools/test.sh" "readme.md references the .tools/test.sh entry point"
	require_in_file "${readme}" "One entry point to invoke all tests and quality checks." "readme.md carries the single-entry-point design decision"

	# .tools/test.sh structure.
	local test_sh="${project_dir}/.tools/test.sh"
	require_in_file "${test_sh}" "HADOLINT" "test.sh runs the hadolint section"
	require_in_file "${test_sh}" "shfmt" "test.sh runs the shell format-check section"
	require_in_file "${test_sh}" "shellcheck" "test.sh runs the shellcheck section"
	# The final banner must be the last statement; project cleanup or notes belong
	# above it so "ALL CHECKS PASSED" is the last thing a green run prints.
	local last_statement
	last_statement="$(awk 'NF && $0 !~ /^[[:space:]]*#/ { line = $0 } END { print line }' "${test_sh}")"
	if [[ "${last_statement}" == *"ALL CHECKS PASSED"* ]]; then
		echo "✓ test.sh ends with the ALL CHECKS PASSED banner"
	else
		echo "✗ test.sh ends with the ALL CHECKS PASSED banner"
		invariant_failures=$((invariant_failures + 1))
	fi

	# Shell conventions on every project script.
	local script rel
	while IFS= read -r -d '' script; do
		rel="${script#"${project_dir}/"}"
		require_in_file "${script}" "#!/usr/bin/env bash" "${rel}: bash shebang"
		require_in_file "${script}" "set -o errexit -o nounset -o noglob -o pipefail" "${rel}: defensive set options header"
		require_regex_in_file "${script}" '^PS4=' "${rel}: PS4 trace header"
	done < <(find "${project_dir}" -type f -name '*.sh' -not -path '*/.git/*' -not -path '*/node_modules/*' -print0 | sort -z)

	# devcontainer conventions.
	local containerfile="${project_dir}/.devcontainer/Containerfile"
	local devcontainer_json="${project_dir}/.devcontainer/devcontainer.json"
	require_in_file "${containerfile}" "NOTE: Put everything specific to this repository" "Containerfile documents the repo-specific block"
	require_pattern_count "${containerfile}" '^# ---$' "2" "Containerfile fences the repo-specific block with exactly two markers"
	require_regex_in_file "${containerfile}" '^FROM .*@sha256:[0-9a-f]' "Containerfile pins the base image by digest"
	require_in_file "${devcontainer_json}" "\"remoteUser\": \"vscode\"" "devcontainer.json drops to the vscode user"
	require_in_file "${devcontainer_json}" "USER_UID" "devcontainer.json maps the host UID"
	require_in_file "${devcontainer_json}" "USER_GID" "devcontainer.json maps the host GID"
}

print_summary() {
	print_header "SUMMARY"

	echo "Compared ${#shared_files[@]} whole files across ${#projects[@]} projects"
	echo "Compared ${#shared_regions[@]} shared regions and invariants across ${#projects_in_scope[@]} projects in scope"
	echo "  Identical file pairs:  ${matched_count}"
	echo "  Differing file pairs:  ${diff_count}"
	echo "  Missing files:         ${missing_count}"
	echo "  Invariant failures:    ${invariant_failures}"
}

validate_reference() {
	if [ ! -d "${workspace_dir}/${reference}/.devcontainer" ]; then
		echo "ERROR: reference project '${reference}' has no .devcontainer directory in ${workspace_dir}" >&2
		echo "Run this script from the parent directory of the '${reference}' project." >&2
		exit 1
	fi
}

main() {
	echo "==================== DEVELOPER TOOLING DRIFT REPORT ===================="
	echo "Workspace: ${workspace_dir}"

	discover_projects
	validate_reference

	echo "Projects:  ${projects[*]}"

	report_projects_without_devcontainer

	local file
	for file in "${shared_files[@]}"; do
		compare_file_against_reference "${file}" "${projects[@]}"
	done

	for file in "${shared_regions[@]}"; do
		compare_file_against_reference "${file}" "${projects_in_scope[@]}"
	done

	compare_cross_check "${cross_check_a}" "${cross_check_b}"

	local project
	for project in "${projects_in_scope[@]}"; do
		check_project_invariants "${project}"
	done

	print_summary
}

main "$@"
