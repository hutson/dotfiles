#!/usr/bin/env bash

#! Set up a local environment.
# Set up a local environment containing all tools and libraries needed for development and personal use.
setupEnvironment() {
	printf "\n> Removing %s directory.\n" "${HOMEBREW_PREFIX}"

	# Clear out the local system directory.
	if [ -d "${HOMEBREW_PREFIX}" ]; then
		rm -fr "${HOMEBREW_PREFIX}" &>/dev/null
	fi

	setupHomeBrew
	installBrewPackages
	brew cleanup -s

	installNodePackages
	nvim --headless -c "lua vim.pack.update(nil, { force = true, target = 'lockfile' })" -c "qa!"
}

#! Update environment.
# Update the development environment by installing the latest version of all managed tools.
updateEnvironment() {
	printf "\n> Updating Environment.\n"

	# Update Homebrew and the list of available packages/updates.
	brew update

	# Upgrade all Brew-installed packages, including those that manage their own upgrades through auto-updates (--greedy).
	brew upgrade --greedy

	# Remove old/outdated downloads and formulae, along with purging the cache, to free up disk space. The cache could improve performance in future upgrades, but this optimizes for reducing disk space usage, which is a bigger constraint in the containerized environments where we use Homebrew.
	brew cleanup --scrub --prune=all

	installNodePackages
	nvim --headless -c "lua vim.pack.update(nil, { force = true, target = 'lockfile' })" -c "qa!"
}

#! Update lock state.
# Update all lockfiles and other hard-coded versions used to install and manage third-party software referenced by this dotfile project.
updateLockState() {
	printf "\n> Updating lockfiles and hard-coded versions.\n"

	nvim --headless -c "lua vim.pack.update(nil, { force = true })" -c "qa!"

	# TODO: Extend to include lockfiles for fnm (Node.js version), Brew (Brewfile.lock), and pinned AppImage hashes.

	# TODO: Display a diff of changed lockfiles and prompt the user to confirm before committing.
}

#! Set up Homebrew.
# Install Homebrew locally to enable downloading, building, and installing tools from source.
setupHomeBrew() {
	printf "\n> Installing Homebrew.\n"

	# Create the Homebrew prefix directory; required before tar extraction.
	mkdir -p "${HOMEBREW_PREFIX}/Homebrew"

	# Download a tarball of the `master` branch rather than cloning, because
	# git is not yet available (installed later via Brew).
	curl -L https://github.com/Homebrew/brew/archive/master.tar.gz -o "/tmp/homebrew.tar.gz"

	tar -xf "/tmp/homebrew.tar.gz" -C "${HOMEBREW_PREFIX}/Homebrew/" --strip-components=1

	# Symlink the dedicated brew binary into the Homebrew binary directory.
	mkdir -p "${HOMEBREW_PREFIX}/bin/"
	ln -s "${HOMEBREW_PREFIX}/Homebrew/bin/brew" "${HOMEBREW_PREFIX}/bin/"

	rm -f "/tmp/homebrew.tar.gz"
}

#! Install packages via Homebrew.
# Install all packages needed for the development environment using Homebrew's package manager.
installBrewPackages() {
	if ! command -v brew &>/dev/null; then
		echo "ERROR: 'brew' is required for building and installing tools from source, but it's not available in your PATH. Please install 'brew' and ensure it's in your PATH. Then re-run 'installBrewPackages'."
		return 1
	fi

	printf "\n> Installing Brew packages.\n"

	# Install the latest Bash shell for access to modern features.
	brew install bash

	# Install bash-completion. This allows us to leverage bash completion scripts installed by our brew-installed packages. Version @2 is required for Bash > 2.
	brew install bash-completion@2

	# Install ncdu, a command-line tool for displaying disk usage information.
	brew install ncdu

	# Output file contents with syntax highlighting and Git integration.
	brew install bat

	# Linter for shell scripts, including Bash.
	brew install shellcheck

	# Linter for Containerfiles.
	brew install hadolint

	# Linter for YAML files.
	brew install yamllint

	# Install shell script formatter.
	brew install shfmt

	# Install Go compiler and development stack.
	brew install go
	brew install gopls # Language server for Go.

	# Language server for Markdown.
	brew install marksman

	# Language server for Lua.
	brew install lua-language-server

	# Install a CLI tool for managing Node interpreter versions within the current shell environment.
	brew install fnm
	eval "$(fnm env)"

	# Install Git version control.
	brew install git

	# Install Git LFS for managing large binary files via text pointers. Requires a remote Git server with LFS support.
	brew install git-lfs

	# Install command-line text editor.
	brew install neovim
	brew install ripgrep

	# Fancy cross-shell command-line prompt.
	brew install starship

	if [ "$(uname)" = "Darwin" ]; then
		# Install cross-platform terminal emulator.
		brew install ghostty

		# Latest GNU core utilities, such as `rm`, `ls`, etc.
		brew install coreutils

		# Docker/container support.
		brew install colima
		brew install docker

		# Store Docker Hub credentials in the macOS Keychain for improved security.
		brew install docker-credential-helper

		# Install resource orchestration tool.
		brew install terraform
		brew install hashicorp/tap/terraform-ls # Language server for Terraform.

		brew install wget

		# Required to get a prompt for a security key PIN when using GPG for SSH authentication on Mac devices.
		brew install pinentry-mac
		brew install gpg

		brew install yubico-authenticator
		brew install firefox@esr
		brew install gpg-suite
		brew install keepassxc
		brew install obs
	else
		# TODO: Replace with Homebrew package, or Flatpak package, when available.
		wget --quiet https://github.com/pkgforge-dev/ghostty-appimage/releases/download/v1.2.3/Ghostty-1.2.3-x86_64.AppImage -O "${HOMEBREW_PREFIX}/bin/ghostty"
		echo "cf239a0a9383aa9a148da2f6c6444993f871618cf4309d4db15d7be992d16725 ${HOMEBREW_PREFIX}/bin/ghostty" | sha256sum -c -
		chmod +x "${HOMEBREW_PREFIX}/bin/ghostty"

		# Used to interact with the X11 system clipboard for Neovim.
		brew install xclip

		# Static site generator and build tool.
		brew install hugo

		# Tool for managing offline video archives.
		brew install yt-dlp
	fi
}

#! Install Node.js packages.
# Install Node.js packages via `npm`.
installNodePackages() {
	if ! command -v fnm &>/dev/null; then
		echo "ERROR: 'fnm' is required for installing NodeJS packages, but it's not available in your PATH. Please install 'fnm' and ensure it's in your PATH. Then re-run 'installNodePackages'."
		return 1
	fi

	printf "\n> Installing Node packages.\n"

	fnm install 24 # Latest LTS at time of writing.

	# Language server for the Bash language.
	# TODO: Switch this back to the Homebrew package `bash-language-server` as soon as we address the burden of needing to
	#       download and compile the Node.js package, which takes considerable time and system resources.
	npm install -g bash-language-server
}

#! Compress a file or folder into an archive.
# Supports multiple archive formats determined by the archive type argument.
# This function is based on http://bijayrungta.com/extract-and-compress-files-from-command-line-in-linux
#
# \param $1 Path to the file or folder to be archived.
# \param $2 Archive type; such as 'tar' or 'zip'.
compress() {
	local dirPriorToExe
	dirPriorToExe="$(pwd)"
	local dirName
	dirName="$(dirname "${1}")"
	local baseName
	baseName="$(basename "${1}")"

	if [ -f "${1}" ]; then
		echo "Selected a file for compression. Changing directory to '${dirName}''."
		cd "${dirName}" || exit
		case "${2}" in
		tar.bz2) tar cjf "${baseName}.tar.bz2" "${baseName}" ;;
		tar.gz) tar czf "${baseName}.tar.gz" "${baseName}" ;;
		gz) gzip "${baseName}" ;;
		tar) tar -cvvf "${baseName}.tar" "${baseName}" ;;
		zip) zip -r "${baseName}.zip" "${baseName}" ;;
		*)
			echo "A compression format was not chosen. Defaulting to tar.gz"
			tar czf "${baseName}.tar.gz" "${baseName}"
			;;
		esac
		echo "Navigating back to ${dirPriorToExe}"
		cd "${dirPriorToExe}" || exit
	elif [ -d "${1}" ]; then
		echo "Selected a directory for compression. Changing directory to '${dirName}''."
		cd "${dirName}" || exit
		case "${2}" in
		tar.bz2) tar cjf "${baseName}.tar.bz2" "${baseName}" ;;
		tar.gz) tar czf "${baseName}.tar.gz" "${baseName}" ;;
		gz) gzip -r "${baseName}" ;;
		tar) tar -cvvf "${baseName}.tar" "${baseName}" ;;
		zip) zip -r "${baseName}.zip" "${baseName}" ;;
		*)
			echo "A compression format was not chosen. Defaulting to tar.gz"
			tar czf "${baseName}.tar.gz" "${baseName}"
			;;
		esac
		echo "Navigating back to ${dirPriorToExe}"
		cd "${dirPriorToExe}" || exit
	else
		echo "'${1}' is not a valid file or directory."
	fi
}

#! Extract an archive file.
# Automatically detects the archive format from the file extension and applies the appropriate extraction method.
# This function is based on https://github.com/xvoland/Extract.
#
# \param $1 Path to the archive file.
extract() {
	if [ -z "${1}" ]; then
		echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
		exit
	fi

	if [ -f "${1}" ]; then
		case "${1}" in
		*.tar.bz2) tar xvjf "${1}" ;;
		*.tar.gz) tar xvzf "${1}" ;;
		*.tar.xz) tar xvJf "${1}" ;;
		*.lzma) unlzma "${1}" ;;
		*.bz2) bunzip2 "${1}" ;;
		*.rar) unrar x -ad "${1}" ;;
		*.gz) gunzip "${1}" ;;
		*.tar) tar xvf "${1}" ;;
		*.tbz2) tar xvjf "${1}" ;;
		*.tgz) tar xvzf "${1}" ;;
		*.zip) unzip "${1}" ;;
		*.Z) uncompress "${1}" ;;
		*.7z) 7z x "${1}" ;;
		*.xz) unxz "${1}" ;;
		*.exe) cabextract "${1}" ;;
		*) echo "extract: '${1}' - unknown archive method" ;;
		esac
	else
		echo "${1} - file does not exist"
	fi
}

#! Convert a Zip file to a compressed Tar file (*.tar.gz).
# Take a Zip file, extract the contents to a temporary directory, and then re-archive the extracted contents into a compressed Tar file.
#
# \param $1 Path to the Zip archive file.
convertZip() {
	tmpdir="$(mktemp -d)"

	unzip -q "${1}" -d "${tmpdir}/"

	outfilename="$(basename "${1}" | rev | cut -d. -f2- | rev).tar"

	tar --create --exclude="${outfilename}" --file="${tmpdir}/${outfilename}" -C "${tmpdir}/" .

	pigz -9 "${tmpdir}/${outfilename}"

	mv "${tmpdir}/${outfilename}.gz" "$(dirname "${1}")"

	rm -rf "${tmpdir}"
	rm -f "${1}"
}

#! Display repository status of all Git repositories.
# Recursively scan the current working directory for Git repositories and display their current branch, uncommitted changes, and remote tracking status. The intent is to provide a quick overview of the status of code repositories to avoid forgetting to commit and push changes.
gits() {
	local currentWorkingDirectory
	currentWorkingDirectory="$(pwd)"

	find . -type d -name ".git" 2>/dev/null | while read -r gitDirectory; do
		local repositoryDirectory
		repositoryDirectory="$(dirname "${gitDirectory}")"

		if cd "${repositoryDirectory}" 2>/dev/null; then
			printf "\n\033[36mRepository: %s\033[0m\n" "${repositoryDirectory#./}"

			printf "  Branch:\n"
			git -c color.ui=always branch -v 2>/dev/null | sed 's/^/    /'

			local gitStatusOutput
			gitStatusOutput="$(git -c color.ui=always status --short 2>/dev/null)"
			if [ -n "${gitStatusOutput}" ]; then
				printf "  Changes:\n"
				printf "%s\n" "${gitStatusOutput}" | sed 's/^/    /'
			fi

			local remoteStatusInfo
			remoteStatusInfo="$(git -c color.ui=always status 2>/dev/null | grep -E "Your branch is (ahead|behind|up to date|have diverged)")"
			if [ -n "${remoteStatusInfo}" ]; then
				printf "  Remote:\n"
				printf "    %s\n" "${remoteStatusInfo}"
			fi

			cd "${currentWorkingDirectory}" || exit
		fi
	done
}

#! Back up application data that lacks an export mechanism.
# Back up application data (e.g., game saves) to a user-specified directory. Targets applications that lack a built-in export or backup mechanism.
backup() {
	printf "Enter backup directory name: "
	read -r backupDirName

	if [ -z "${backupDirName}" ]; then
		echo "ERROR: Backup directory name cannot be empty."
		return 1
	fi

	local backupPath="${HOME}/${backupDirName}"
	if [ ! -d "${backupPath}" ]; then
		mkdir -p "${backupPath}"
	fi

	# Handle Flatpak applications.
	# Someday maintaining backups of application data from Flatpak
	# applications will be handled for us by Flatpak itself:
	# - https://github.com/flatpak/flatpak/issues/1356
	local flatpakApps=(
		"io.github.endless_sky.endless_sky"
	)
	for appName in "${flatpakApps[@]}"; do
		printf "\n> Processing %s\n" "${appName}"

		local sourceDataDir="${HOME}/.var/app/${appName}"
		if [ ! -d "${sourceDataDir}" ]; then
			echo "WARNING: Data directory ${sourceDataDir} does not exist for ${appName}. Skipping."
			continue
		fi

		local targetDir="${backupPath}/Flatpaks/${appName}"
		mkdir -p "${targetDir}"
		if rsync -a --delete --exclude="cache/" "${sourceDataDir}/" "${targetDir}/" 2>/dev/null; then
			printf "  ✓ Successfully backed up %s\n" "${appName}"
		else
			printf "  ✗ Failed to backup %s\n" "${appName}"
		fi
	done
}
