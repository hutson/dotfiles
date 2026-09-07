#!/usr/bin/env bash

set -o errexit -o nounset -o noglob -o pipefail
readonly _trace_start_time_us=${EPOCHREALTIME//./}
PS4='[DEBUGLEVEL:${SHLVL} SUBSHELL:${BASH_SUBSHELL} LINE:${LINENO} DIFF:$(us=$(( ${EPOCHREALTIME//./} - _trace_start_time_us )); ms=$(( us / 1000 )); printf "%d.%03d" $((ms / 1000)) $((ms % 1000)) )s SOURCE:${BASH_SOURCE}] '

# This file exists to install a minimum shell environment within a Dev Container environment.
# The user environment should only contain those aliases, tools, and configuration, needed to
# simplify the user's experience. No tools should be installed that might conflict with the
# tooling pre-installed by the Dev Container environment responsible for building and testing
# the given project.

cat <<-'EOF' >"${XDG_CONFIG_HOME}/Brewfile"
	brew "opencode"
	brew "starship"
EOF

bash deploy.sh
# '~/.bash_functions' is a symlink deployed into the home directory by 'deploy.sh', so its
# location is not resolvable from the repository; the source file is still covered by
# '.tools/test.sh' on its own.
# shellcheck source=/dev/null
source ~/.bash_functions
setupHomeBrew
brew bundle
