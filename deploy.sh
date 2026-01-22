#!/usr/bin/env bash

set -euf -o pipefail

# Get the project name from the current directory.
project_name="$(basename "$(pwd)")"

echo "==================== DEPLOYING ${project_name^^} ===================="
echo "Starting dotfiles deployment..."
echo

# If the XDG configuration home directory is not already set within the current environment, then default it to the value below, which matches the XDG specification.
if [ -z "${XDG_CONFIG_HOME}" ]; then
	export XDG_CONFIG_HOME="${HOME}/.config"
fi

# Symlink files into the user's home directory.
echo "> Symlinking files into the user's home directory (${HOME})."
find . -maxdepth 1 -type f -name '.*' -exec ln -s -f "$(pwd)/{}" "${HOME}/{}" \;

# Symlink SSH files.
# Note: Must set `.ssh` directory to 700 to protect files and because some programs may throw a permission error if they see a globally readable symlink file (Which is unavoidable) in the `.ssh` directory. Setting the directory's permissions to be more restrictive usually avoids the error.
echo "> Symlinking SSH files into the SSH directory (${HOME}/.ssh)."
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"
ln -s -f "$(pwd)/.ssh/config" "${HOME}/.ssh/config"
ln -s -f "$(pwd)/.ssh/allowed_signers" "${HOME}/.ssh/allowed_signers"

# Symlink GNUPG files.
echo "> Symlinking GNUPG files into GNUPG directory (${HOME}/.gnupg)."
mkdir -p "${HOME}/.gnupg"
ln -s -f "$(pwd)/.gnupg/gpg.conf" "${HOME}/.gnupg/gpg.conf"
ln -s -f "$(pwd)/.gnupg/gpg-agent.conf" "${HOME}/.gnupg/gpg-agent.conf"

# Symlink Neovim configuration files.
echo "> Symlinking Neovim files into the config directory (${XDG_CONFIG_HOME}/nvim)."
mkdir -p "${XDG_CONFIG_HOME}/nvim"
ln -s -f "$(pwd)/.config/nvim/init.lua" "${XDG_CONFIG_HOME}/nvim/init.lua"

# Symlink Ghostty configuration files.
echo "> Symlinking Ghostty files into the config directory (${XDG_CONFIG_HOME}/ghostty)."
mkdir -p "${XDG_CONFIG_HOME}/ghostty"
ln -s -f "$(pwd)/.config/ghostty/config" "${XDG_CONFIG_HOME}/ghostty/config"

# Symlink Top configuration files.
echo "> Symlinking top files into the config directory (${XDG_CONFIG_HOME}/nvim)."
mkdir -p "${XDG_CONFIG_HOME}/procps"
ln -s -f "$(pwd)/.config/procps/toprc" "${XDG_CONFIG_HOME}/procps/toprc"

# Symlink GenAI rule files.
echo "> Symlinking coding agent files into the config directory (${XDG_CONFIG_HOME}/opencode)."
ln -s -f "$(pwd)/.config/opencode/AGENTS.md" "${XDG_CONFIG_HOME}/opencode/AGENTS.md"
ln -s -f "$(pwd)/.config/opencode/agents" "${XDG_CONFIG_HOME}/opencode/agents"
ln -s -f "$(pwd)/.config/opencode/commands" "${XDG_CONFIG_HOME}/opencode/commands"
ln -s -f "$(pwd)/.config/opencode/skills" "${XDG_CONFIG_HOME}/opencode/skills"

echo
echo "==================== DEPLOYMENT COMPLETE =============="
