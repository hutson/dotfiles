#!/usr/bin/env bash

# Launches the user's EDITOR on a study exercise file and blocks until the
# editor exits. Works automatically inside tmux (split pane); otherwise prints
# manual instructions.

set -o errexit -o nounset -o noglob -o pipefail
readonly _trace_start_time_us=${EPOCHREALTIME//./}
PS4='[DEBUGLEVEL:${SHLVL} SUBSHELL:${BASH_SUBSHELL} LINE:${LINENO} DIFF:$(us=$(( ${EPOCHREALTIME//./} - _trace_start_time_us )); ms=$(( us / 1000 )); printf "%d.%03d" $((ms / 1000)) $((ms % 1000)) )s SOURCE:${BASH_SOURCE}] '

usage() {
	cat <<-'EOF'
		usage: study-editor.sh <file> [timeout-seconds]

		Launch $EDITOR on <file> and block until the editor closes.
		timeout-seconds defaults to 1200 (20 minutes). Callers running this
		script under their own timeout must use a limit larger than the
		script's, so exit code 3 can be reported cleanly.

		Exit codes:
		  0 - editor closed normally
		  2 - could not launch automatically; manual instructions printed
		  3 - timed out waiting for the editor to close
	EOF
}

if [ $# -lt 1 ]; then
	usage >&2
	exit 1
fi

exercise_file=$1
timeout_seconds=${2:-1200}

if [ ! -e "$exercise_file" ]; then
	echo "error: file not found: ${exercise_file}" >&2
	exit 1
fi

if [ -z "${EDITOR:-}" ]; then
	echo "error: EDITOR environment variable is not set" >&2
	exit 1
fi

sentinel="${exercise_file}.done"
rm -f "$sentinel"

print_manual_instructions() {
	# The path is shown quoted with `%q` so a file name shaped by untrusted study
	# material cannot read as extra commands when the user copies this line.
	cat <<-EOF
		Could not launch your editor automatically from this environment.

		Please open the file yourself:

		  \$EDITOR $(printf '%q' "${exercise_file}")

		Then return here and let me know you are done.
	EOF
}

launch_in_tmux() {
	# tmux evaluates its command argument through /bin/sh, so any value spliced into
	# that string is parsed as shell syntax. The exercise file name comes from
	# web-derived study material, so it is never spliced in: the command is written to
	# a launcher script, where the file and sentinel land as `%q`-quoted literals, and
	# tmux is handed only the launcher path, which `mktemp` guarantees is shell-safe.
	# `${EDITOR}` is still written raw into the launcher and still evaluated by a
	# shell, which is what makes a multi-word value such as `nvim -w log` work the way
	# a user would type it; it stays a trusted value because running the user's own
	# editor is the point of this script.
	local launcher
	launcher="$(mktemp)"
	{
		printf '#!/usr/bin/env bash\n'
		printf '%s %q\n' "${EDITOR}" "${exercise_file}"
		# Unconditional, matching the `;` this replaced: a non-zero editor exit must
		# still create the sentinel, or the wait loop below stalls to its full timeout.
		printf 'touch %q\n' "${sentinel}"
		printf 'rm -f -- %q\n' "${launcher}"
	} >"${launcher}"
	# On a failed `split-window` the launcher never runs, so its self-removal never
	# happens; delete it here so a tmux error does not leave a temp file behind.
	tmux split-window -h "$(printf 'bash %q' "${launcher}")" || {
		rm -f -- "${launcher}"
		return 1
	}
}

if [ -n "${TMUX:-}" ]; then
	launch_in_tmux || {
		print_manual_instructions
		exit 2
	}
else
	# TODO: When invoked from inside Ghostty, launch a new Ghostty window running
	# "$EDITOR $exercise_file" with cwd set to the directory containing
	# "$exercise_file" so the user can begin editing immediately, then create the
	# sentinel file after the editor exits so the wait loop returns.
	print_manual_instructions
	exit 2
fi

elapsed=0
while [ ! -e "$sentinel" ]; do
	if [ "$elapsed" -ge "$timeout_seconds" ]; then
		echo "error: timed out after ${timeout_seconds}s waiting for the editor to close" >&2
		exit 3
	fi
	sleep 2
	elapsed=$((elapsed + 2))
done

exit 0
