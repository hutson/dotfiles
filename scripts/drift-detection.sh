#!/usr/bin/env bash

# Compares the .devcontainer/ folders across projects in the current directory to make
# drift in core files and configuration easy to spot. There will always be slight
# differences since projects have different build requirements, but the structure and
# organization should be mostly the same.
#
# This script is intentionally a report tool: it always exits 0, even when drift is
# detected, because cross-project differences are expected.

set -o errexit -o nounset -o noglob -o pipefail
readonly _trace_start_time_us=${EPOCHREALTIME//./}
PS4='[DEBUGLEVEL:${SHLVL} SUBSHELL:${BASH_SUBSHELL} LINE:${LINENO} DIFF:$(us=$(( ${EPOCHREALTIME//./} - _trace_start_time_us )); ms=$(( us / 1000 )); printf "%d.%03d" $((ms / 1000)) $((ms % 1000)) )s SOURCE:${BASH_SOURCE}] '

workspace_dir="$(pwd)"

projects=()
readonly reference=dotfiles
readonly cross_check_a=semantic-tag
readonly cross_check_b=gardening
readonly devcontainer_files=(Containerfile devcontainer.json)

diff_count=0
matched_count=0
missing_count=0

discover_projects() {
	while IFS= read -r -d '' project_path; do
		projects+=("$(basename "${project_path}")")
	done < <(find "${workspace_dir}" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
}

print_header() {
	local header="${1}"
	printf '\n==================== %s ====================\n' "${header}"
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

compare_file_against_reference() {
	local file="${1}"
	local reference_path="${workspace_dir}/${reference}/.devcontainer/${file}"

	for project in "${projects[@]}"; do
		if [ "${project}" = "${reference}" ]; then
			continue
		fi

		if [ ! -d "${workspace_dir}/${project}/.devcontainer" ]; then
			continue
		fi

		local project_path="${workspace_dir}/${project}/.devcontainer/${file}"

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

		if diff -q "${reference_path}" "${project_path}" >/dev/null 2>&1; then
			echo "IDENTICAL"
			matched_count=$((matched_count + 1))
		else
			# diff exits 1 when files differ; with errexit enabled, `|| true`
			# keeps the script alive so the summary counters can record the result.
			diff -u \
				--label "${reference}/.devcontainer/${file}" \
				--label "${project}/.devcontainer/${file}" \
				"${reference_path}" "${project_path}" || true
			diff_count=$((diff_count + 1))
		fi
	done
}

compare_cross_check() {
	local project_a="${1}"
	local project_b="${2}"

	if [ ! -d "${workspace_dir}/${project_a}/.devcontainer" ] || [ ! -d "${workspace_dir}/${project_b}/.devcontainer" ]; then
		print_header "${project_a} vs ${project_b} cross-check"
		echo "SKIPPED: one or both projects have no .devcontainer directory"
		return
	fi

	print_header "${project_a} vs ${project_b} cross-check"

	for file in "${devcontainer_files[@]}"; do
		local path_a="${workspace_dir}/${project_a}/.devcontainer/${file}"
		local path_b="${workspace_dir}/${project_b}/.devcontainer/${file}"

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

		if diff -q "${path_a}" "${path_b}" >/dev/null 2>&1; then
			echo "IDENTICAL"
			matched_count=$((matched_count + 1))
		else
			# diff exits 1 when files differ; with errexit enabled, `|| true`
			# keeps the script alive so the summary counters can record the result.
			diff -u \
				--label "${project_a}/.devcontainer/${file}" \
				--label "${project_b}/.devcontainer/${file}" \
				"${path_a}" "${path_b}" || true
			diff_count=$((diff_count + 1))
		fi
	done
}

devcontainer_project_count() {
	local count=0
	local project
	for project in "${projects[@]}"; do
		if [ -d "${workspace_dir}/${project}/.devcontainer" ]; then
			count=$((count + 1))
		fi
	done
	echo "${count}"
}

print_summary() {
	local project_count
	project_count="$(devcontainer_project_count)"

	print_header "SUMMARY"

	echo "Compared ${#devcontainer_files[@]} devcontainer files across ${project_count} projects"
	echo "  Identical file pairs:  ${matched_count}"
	echo "  Differing file pairs:  ${diff_count}"
	echo "  Missing files:         ${missing_count}"
}

validate_reference() {
	if [ ! -d "${workspace_dir}/${reference}/.devcontainer" ]; then
		echo "ERROR: reference project '${reference}' has no .devcontainer directory in ${workspace_dir}" >&2
		echo "Run this script from the parent directory of the '${reference}' project." >&2
		exit 1
	fi
}

main() {
	echo "==================== DEVCONTAINER DRIFT REPORT ===================="
	echo "Workspace: ${workspace_dir}"

	discover_projects
	validate_reference

	echo "Projects:  ${projects[*]}"

	report_projects_without_devcontainer

	for file in "${devcontainer_files[@]}"; do
		compare_file_against_reference "${file}"
	done

	compare_cross_check "${cross_check_a}" "${cross_check_b}"

	print_summary
}

main "$@"
