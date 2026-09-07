#!/usr/bin/env bash

set -o errexit -o nounset -o noglob -o pipefail
readonly _trace_start_time_us=${EPOCHREALTIME//./}
PS4='[DEBUGLEVEL:${SHLVL} SUBSHELL:${BASH_SUBSHELL} LINE:${LINENO} DIFF:$(us=$(( ${EPOCHREALTIME//./} - _trace_start_time_us )); ms=$(( us / 1000 )); printf "%d.%03d" $((ms / 1000)) $((ms % 1000)) )s SOURCE:${BASH_SOURCE}] '

# This file exists to install a full development environment that includes
# all aliases, tools, and configuration, that the user may need while working.

script_dir="$(cd "$(dirname "${0}")" && pwd)"
if [ "$(pwd)" != "$script_dir" ]; then
	echo "ERROR: This script must be run from its own directory." >&2
	echo "Expected: $script_dir" >&2
	echo "Current:  $(pwd)" >&2
	exit 1
fi

project_name="$(basename "$(pwd)")"

echo "==================== DEPLOYING ${project_name^^} ===================="
echo "Starting dotfiles deployment..."
echo

# If XDG_CONFIG_HOME is unset, default it per the XDG Base Directory
# specification so that downstream symlinks target the correct location.
if [ -z "${XDG_CONFIG_HOME:-}" ]; then
	export XDG_CONFIG_HOME="${HOME}/.config"
fi

echo "> Symlinking files into the user's home directory (${HOME})."
find . -maxdepth 1 -type f -name '.*' ! -name '.gitignore' -exec ln -s -f "$(pwd)/{}" "${HOME}/{}" \;
ln -s -f "$(pwd)/Brewfile" "${XDG_CONFIG_HOME}/Brewfile"

# Note: Must set `.ssh` directory to 700 to protect files and because some programs may throw a permission error if they see a globally readable symlink file (Which is unavoidable) in the `.ssh` directory. Setting the directory's permissions to be more restrictive usually avoids the error.
echo "> Symlinking SSH files into the SSH directory (${HOME}/.ssh)."
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"
ln -s -f "$(pwd)/.ssh/config" "${HOME}/.ssh/config"
ln -s -f "$(pwd)/.ssh/allowed_signers" "${HOME}/.ssh/allowed_signers"

echo "> Symlinking GnuPG files into GnuPG directory (${HOME}/.gnupg)."
mkdir -p "${HOME}/.gnupg"
ln -s -f "$(pwd)/.gnupg/gpg.conf" "${HOME}/.gnupg/gpg.conf"
ln -s -f "$(pwd)/.gnupg/gpg-agent.conf" "${HOME}/.gnupg/gpg-agent.conf"

echo "> Symlinking Neovim files into the config directory (${XDG_CONFIG_HOME}/nvim)."
mkdir -p "${XDG_CONFIG_HOME}/nvim"
ln -s -f "$(pwd)/.config/nvim/init.lua" "${XDG_CONFIG_HOME}/nvim/init.lua"
ln -s -f "$(pwd)/.config/nvim/nvim-pack-lock.json" "${XDG_CONFIG_HOME}/nvim/nvim-pack-lock.json"

echo "> Symlinking Ghostty files into the config directory (${XDG_CONFIG_HOME}/ghostty)."
mkdir -p "${XDG_CONFIG_HOME}/ghostty"
ln -s -f "$(pwd)/.config/ghostty/config" "${XDG_CONFIG_HOME}/ghostty/config"

echo "> Symlinking coding agent files into the config directory (${XDG_CONFIG_HOME}/opencode)."
mkdir -p "${XDG_CONFIG_HOME}/opencode"
ln -s -f "$(pwd)/.config/opencode/opencode.jsonc" "${XDG_CONFIG_HOME}/opencode/opencode.jsonc"
ln -s -f "$(pwd)/.config/opencode/AGENTS.md" "${XDG_CONFIG_HOME}/opencode/AGENTS.md"
ln -s -T -f "$(pwd)/.config/opencode/agents" "${XDG_CONFIG_HOME}/opencode/agents"
ln -s -T -f "$(pwd)/.config/opencode/commands" "${XDG_CONFIG_HOME}/opencode/commands"
ln -s -T -f "$(pwd)/.config/opencode/skills" "${XDG_CONFIG_HOME}/opencode/skills"

echo
echo "==================== DEPLOYMENT COMPLETE =============="
