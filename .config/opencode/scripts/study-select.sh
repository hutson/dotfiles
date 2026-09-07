#!/usr/bin/env bash

# Selects a randomised sequence of study questions from the provided markdown
# skills files, honouring a 3 Easy / 2 Medium / 1 Hard ratio out of every six
# questions, with substitutions and a warning when a difficulty pool is empty.

set -o errexit -o nounset -o noglob -o pipefail
readonly _trace_start_time_us=${EPOCHREALTIME//./}
PS4='[DEBUGLEVEL:${SHLVL} SUBSHELL:${BASH_SUBSHELL} LINE:${LINENO} DIFF:$(us=$(( ${EPOCHREALTIME//./} - _trace_start_time_us )); ms=$(( us / 1000 )); printf "%d.%03d" $((ms / 1000)) $((ms % 1000)) )s SOURCE:${BASH_SOURCE}] '

usage() {
	cat <<-'EOF'
		usage: study-select.sh [--count N] [--exclude file:line ...] file [...]

		Outputs one line per selected question in ask-order:
		  difficulty|file|startline|endline|section

		--count    Number of questions to select (default: 6).
		--exclude  Question id(s) to skip (format: file:startline). Repeatable.
	EOF
}

question_count=6
declare -a excludes=()
declare -a files=()

while [ $# -gt 0 ]; do
	case "$1" in
	--count)
		if [ $# -lt 2 ]; then
			echo "error: --count requires a value" >&2
			exit 1
		fi
		question_count=$2
		shift 2
		;;
	--exclude)
		if [ $# -lt 2 ]; then
			echo "error: --exclude requires a value" >&2
			exit 1
		fi
		excludes+=("$2")
		shift 2
		;;
	-h | --help)
		usage
		exit 0
		;;
	--)
		shift
		break
		;;
	-*)
		echo "error: unknown option: $1" >&2
		usage >&2
		exit 1
		;;
	*)
		files+=("$1")
		shift
		;;
	esac
done

while [ $# -gt 0 ]; do
	files+=("$1")
	shift
done

if [ ${#files[@]} -eq 0 ]; then
	echo "error: at least one skills file is required" >&2
	usage >&2
	exit 1
fi

if [ "$question_count" -lt 1 ]; then
	echo "error: --count must be at least 1" >&2
	exit 1
fi

extract_questions() {
	awk '
		/^## / {
			section = $0
			sub(/^## +/, "", section)
		}
		/^\*\*Question:\*\*/ {
			if (q > 0) {
				records[r++] = diff "|" FILENAME "|" q "|" NR "|" section
			}
			q = NR
		}
		/^\*\*Difficulty:\*\* (Easy|Medium|Hard)$/ {
			if (q > 0) {
				diff = $2
			}
		}
		END {
			if (q > 0) {
				records[r++] = diff "|" FILENAME "|" q "|" (NR + 1) "|" section
			}
			for (i = 0; i < r; i++) {
				print records[i]
			}
		}
	' "$@"
}

is_excluded() {
	local id=$1
	local exclusion
	for exclusion in "${excludes[@]}"; do
		if [ "$id" = "$exclusion" ]; then
			return 0
		fi
	done
	return 1
}

# shellcheck disable=SC2178
consume_front() {
	local -n pool=$1
	local n=$2
	local i

	for ((i = 0; i < n && ${#pool[@]} > 0; i++)); do
		printf '%s\n' "${pool[0]}"
		unset 'pool[0]'
		pool=("${pool[@]}")
	done
}

# shellcheck disable=SC2178
remove_item() {
	local -n pool=$1
	local target=$2
	local new_pool=()
	local item

	for item in "${pool[@]}"; do
		if [ "$item" != "$target" ]; then
			new_pool+=("$item")
		fi
	done
	pool=("${new_pool[@]}")
}

# shellcheck disable=SC2178
shuffle_array() {
	local -n arr=$1

	if [ ${#arr[@]} -eq 0 ]; then
		return 0
	fi
	mapfile -t arr < <(printf '%s\n' "${arr[@]}" | shuf)
}

mapfile -t raw_questions < <(extract_questions "${files[@]}")

declare -a easy=() medium=() hard=()
for line in "${raw_questions[@]}"; do
	file=${line#*|}
	file=${file%%|*}
	start=${line#*|*|}
	start=${start%%|*}
	id="${file}:${start}"

	if is_excluded "$id"; then
		continue
	fi

	difficulty=${line%%|*}
	case "$difficulty" in
	Easy)
		easy+=("$line")
		;;
	Medium)
		medium+=("$line")
		;;
	Hard)
		hard+=("$line")
		;;
	esac
done

shuffle_array easy
shuffle_array medium
shuffle_array hard

declare -a warnings=()
selected=0

while [ "$selected" -lt "$question_count" ]; do
	remaining=$((question_count - selected))
	block_size=6
	if [ "$remaining" -lt "$block_size" ]; then
		block_size=$remaining
	fi

	declare -a block=()

	take_easy=3
	if [ "$block_size" -lt "$take_easy" ]; then
		take_easy=$block_size
	fi
	if [ ${#easy[@]} -lt "$take_easy" ]; then
		take_easy=${#easy[@]}
		if [ "$block_size" -eq 6 ]; then
			warnings+=("Easy question pool exhausted; substituting from remaining pools")
		fi
	fi
	mapfile -t picked < <(consume_front easy "$take_easy")
	block+=("${picked[@]}")

	take_medium=2
	block_remaining=$((block_size - ${#block[@]}))
	if [ "$block_remaining" -lt "$take_medium" ]; then
		take_medium=$block_remaining
	fi
	if [ ${#medium[@]} -lt "$take_medium" ]; then
		take_medium=${#medium[@]}
		if [ "$block_size" -eq 6 ]; then
			warnings+=("Medium question pool exhausted; substituting from remaining pools")
		fi
	fi
	mapfile -t picked < <(consume_front medium "$take_medium")
	block+=("${picked[@]}")

	take_hard=1
	block_remaining=$((block_size - ${#block[@]}))
	if [ "$block_remaining" -lt "$take_hard" ]; then
		take_hard=$block_remaining
	fi
	if [ ${#hard[@]} -lt "$take_hard" ]; then
		take_hard=${#hard[@]}
		if [ "$block_size" -eq 6 ]; then
			warnings+=("Hard question pool exhausted; substituting from remaining pools")
		fi
	fi
	mapfile -t picked < <(consume_front hard "$take_hard")
	block+=("${picked[@]}")

	block_remaining=$((block_size - ${#block[@]}))
	if [ "$block_remaining" -gt 0 ]; then
		if [ ${#easy[@]} -gt 0 ] || [ ${#medium[@]} -gt 0 ] || [ ${#hard[@]} -gt 0 ]; then
			warnings+=("Difficulty pool(s) exhausted before completing the block; substituting from remaining pools")
			declare -a union=()
			union+=("${easy[@]}")
			union+=("${medium[@]}")
			union+=("${hard[@]}")
			shuffle_array union

			take_union=$block_remaining
			if [ ${#union[@]} -lt "$take_union" ]; then
				take_union=${#union[@]}
			fi
			for ((i = 0; i < take_union; i++)); do
				item=${union[$i]}
				block+=("$item")
				remove_item easy "$item" || true
				remove_item medium "$item" || true
				remove_item hard "$item" || true
			done
		fi
	fi

	if [ ${#block[@]} -eq 0 ]; then
		break
	fi

	selected=$((selected + ${#block[@]}))
	printf '%s\n' "${block[@]}" | shuf
done

if [ ${#warnings[@]} -gt 0 ]; then
	printf '%s\n' "${warnings[@]}" | sort -u >&2
fi
