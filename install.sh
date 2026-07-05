#!/usr/bin/env bash

set -euf -o pipefail

# This file exists to install a minimum shell environment within a Dev Container environment.
# The user environment should only contain those aliases, tools, and configuration, needed to
# simplify the user's experience. No tools should be installed that might conflict with the
# tooling pre-installed by the Dev Container environment responsible for building and testing
# the given project.

# Verify script is run from its own directory.
script_dir="$(cd "$(dirname "${0}")" && pwd)"
if [ "$(pwd)" != "$script_dir" ]; then
	echo "ERROR: This script must be run from its own directory." >&2
	echo "Expected: $script_dir" >&2
	echo "Current:  $(pwd)" >&2
	exit 1
fi

# Get the project name from the current directory.
project_name="$(basename "$(pwd)")"

echo "==================== DEPLOYING ${project_name^^} ===================="
echo "Starting dotfiles deployment..."
echo

# If XDG_CONFIG_HOME is unset, default it per the XDG Base Directory
# specification so that downstream symlinks target the correct location.
if [ -z "${XDG_CONFIG_HOME:-}" ]; then
	export XDG_CONFIG_HOME="${HOME}/.config"
fi

# Symlink files into the user's home directory.
echo "> Symlinking files into the user's home directory (${HOME})."
# Exclude `.gitignore` so repository metadata is not symlinked into `${HOME}`.
find . -maxdepth 1 -type f -name '.*' ! -name '.gitignore' -exec ln -s -f "$(pwd)/{}" "${HOME}/{}" \;

# Symlink SSH files.
# Note: Must set `.ssh` directory to 700 to protect files and because some programs may throw a permission error if they see a globally readable symlink file (Which is unavoidable) in the `.ssh` directory. Setting the directory's permissions to be more restrictive usually avoids the error.
echo "> Symlinking SSH files into the SSH directory (${HOME}/.ssh)."
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"
ln -s -f "$(pwd)/.ssh/config" "${HOME}/.ssh/config"
ln -s -f "$(pwd)/.ssh/allowed_signers" "${HOME}/.ssh/allowed_signers"

# Symlink GnuPG files.
echo "> Symlinking GnuPG files into GnuPG directory (${HOME}/.gnupg)."
mkdir -p "${HOME}/.gnupg"
ln -s -f "$(pwd)/.gnupg/gpg.conf" "${HOME}/.gnupg/gpg.conf"
ln -s -f "$(pwd)/.gnupg/gpg-agent.conf" "${HOME}/.gnupg/gpg-agent.conf"

# Symlink GenAI rule files.
echo "> Symlinking coding agent files into the config directory (${XDG_CONFIG_HOME}/opencode)."
mkdir -p "${XDG_CONFIG_HOME}/opencode"
ln -s -f "$(pwd)/.config/opencode/opencode.jsonc" "${XDG_CONFIG_HOME}/opencode/opencode.jsonc"
ln -s -f "$(pwd)/.config/opencode/AGENTS.md" "${XDG_CONFIG_HOME}/opencode/AGENTS.md"
ln -s -T -f "$(pwd)/.config/opencode/agents" "${XDG_CONFIG_HOME}/opencode/agents"
ln -s -T -f "$(pwd)/.config/opencode/commands" "${XDG_CONFIG_HOME}/opencode/commands"
ln -s -T -f "$(pwd)/.config/opencode/skills" "${XDG_CONFIG_HOME}/opencode/skills"

mkdir -p "${HOME}/.local/bin"

# Download each release to a temporary file and verify its SHA-256 checksum
# before extraction to prevent executing tampered or corrupted archives.
opencode_archive="$(mktemp)"
expected_opencode_sha256="06a79c5bb7f8d01716b2440712cf67facd36db59188809aeb232374b206bd429"
curl -sSL "https://github.com/anomalyco/opencode/releases/download/v1.16.2/opencode-linux-x64.tar.gz" -o "${opencode_archive}"
echo "${expected_opencode_sha256}  ${opencode_archive}" | sha256sum --check --strict
tar -xzf "${opencode_archive}" -C "${HOME}/.local/bin" opencode
rm "${opencode_archive}"

starship_archive="$(mktemp)"
expected_starship_sha256="4488c11ca632327d1f1f16fb2f102c0646094c35479cd5435991385da43c61ac"
curl -sSL "https://github.com/starship/starship/releases/download/v1.25.1/starship-x86_64-unknown-linux-gnu.tar.gz" -o "${starship_archive}"
echo "${expected_starship_sha256}  ${starship_archive}" | sha256sum --check --strict
tar -xzf "${starship_archive}" -C "${HOME}/.local/bin" starship
rm "${starship_archive}"

# TODO: Authenticate the opencode CLI with the opencode-go API so AI-assisted
# features work without the user manually running `opencode login`. The user
# must perform authentication interactively after deployment; this script
# cannot securely embed credentials.

echo
echo "==================== DEPLOYMENT COMPLETE =============="
