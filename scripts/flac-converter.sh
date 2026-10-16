#!/usr/bin/env bash

set -o errexit -o nounset -o noglob -o pipefail
readonly _trace_start_time_us=${EPOCHREALTIME//./}
PS4='[DEBUGLEVEL:${SHLVL} SUBSHELL:${BASH_SUBSHELL} LINE:${LINENO} DIFF:$(us=$(( ${EPOCHREALTIME//./} - _trace_start_time_us )); ms=$(( us / 1000 )); printf "%d.%03d" $((ms / 1000)) $((ms % 1000)) )s SOURCE:${BASH_SOURCE}] '

# Convert uncompressed WAV-formatted audio files to compressed FLAC-formatted files
# within the current directory. Converting to FLAC provides smaller file sizes, while
# retaining all audio information.

# `set -o noglob` disables filename expansion, so a `*.wav` glob would iterate over a
# literal string; null-delimited find also tolerates spaces in file names and exits
# cleanly when no WAV files exist.
while IFS= read -r -d '' file; do
	# Extract the file name, minus the directory and the file extension.
	file_name="${file##*/}"
	file_name="${file_name%.wav}"

	# Re-compress using FLAC.
	flac --verify --best "$file" "$file_name.flac" </dev/null
done < <(find . -maxdepth 1 -type f -name '*.wav' -print0 | sort -z)
