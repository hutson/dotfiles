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
	cat <<-EOF
		Could not launch your editor automatically from this environment.

		Please open the file yourself:

		  \$EDITOR "${exercise_file}"

		Then return here and let me know you are done.
	EOF
}

launch_in_tmux() {
	# tmux runs the command through a shell, so word-splitting on $EDITOR is
	# intentional and matches how a user would type it.
	# shellcheck disable=SC2086
	tmux split-window -h "$EDITOR \"${exercise_file}\"; touch \"${sentinel}\""
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
