---
name: Bash
description: Portable, defensive shell scripting: POSIX compliance, quoting, safe set options, and tracing. Load when writing or reviewing Bash or shell scripts.
---

## Conventions

- Prefer POSIX-compliant syntax, such as `test` or single `[` brackets, to improve portability across different Unix-like operating systems.
- Prefer the full argument name when passing flags to commands (e.g., use --help instead of -h).
- Always use double quotes around variable expansion to prevent word splitting and globbing; `"$speed"`
- Always use curly brackets around variable expansion to avoid ambiguity; `"${speed}mph"` when the variable is `$speed`
- Always use `$(...)` for command substitution instead of backticks (`` `...` ``).
- Use defensive shell scripting best practices: such as `set -o errexit -o nounset -o noglob -o pipefail` at the start of bash scripts for safety.
- Avoid the use of `eval`.
- Prefer the long form (`-o errexit`, `-o nounset`, `-o noglob`, `-o pipefail`) over the short form (`-euf -o pipefail`) for `set` options in bash scripts, consistent with using the full argument name for command flags.
- After calling `set -o errexit -o nounset -o noglob -o pipefail`, capture the script start time as a readonly variable and set `PS4` to reference it. The start time is cached once in `_trace_start_time_us` to avoid fragile partial-expansion tricks inside the `PS4` string. This requires bash 5.0+ because it uses `EPOCHREALTIME` and pure-bash integer arithmetic, eliminating the need for external `date` and `bc` calls during tracing:
  ```bash
    readonly _trace_start_time_us=${EPOCHREALTIME//./}
    PS4='[DEBUGLEVEL:${SHLVL} SUBSHELL:${BASH_SUBSHELL} LINE:${LINENO} DIFF:$(us=$(( ${EPOCHREALTIME//./} - _trace_start_time_us )); ms=$(( us / 1000 )); printf "%d.%03d" $((ms / 1000)) $((ms % 1000)) )s SOURCE:${BASH_SOURCE}] '
  ```

## Verify

- `shellcheck -x` is the static-analysis gate for shell scripts; configure it for maximum rigor in the project's config file.
- `shfmt -d` is the format gate; scripts must already be formatted (`shfmt -w` fixes them).
- Use `bash -x` only when testing a change or bug in a Bash script itself, not when merely running a script that happens to be written in Bash.
