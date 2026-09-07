#!/usr/bin/env bash

#! Update environment.
# Update the development environment by installing the latest version of all managed tools.
updateEnvironment() {
	printf "\n> Updating Environment.\n"

	brew bundle --file "${XDG_CONFIG_HOME}/Brewfile"

	nvim --headless -c "lua vim.pack.update(nil, { force = true, target = 'lockfile' })" -c "qa!"
}

#! Set up a local environment.
# Set up a local environment containing all tools and libraries needed for development and personal use.
setupEnvironment() {
	printf "\n> Setting Up Environment.\n"

	# Clear out the local system directory.
	if [ -d "${HOMEBREW_PREFIX}" ]; then
		printf "\n>> Removing %s directory.\n" "${HOMEBREW_PREFIX}"
		rm -rf "${HOMEBREW_PREFIX}" &>/dev/null
	fi

	setupHomeBrew

	updateEnvironment

	# TODO: Replace with Homebrew package, or Flatpak package, when available.
	wget --quiet https://github.com/pkgforge-dev/ghostty-appimage/releases/download/v1.2.3/Ghostty-1.2.3-x86_64.AppImage -O "${HOMEBREW_PREFIX}/bin/ghostty"
	echo "cf239a0a9383aa9a148da2f6c6444993f871618cf4309d4db15d7be992d16725 ${HOMEBREW_PREFIX}/bin/ghostty" | sha256sum -c -
	chmod +x "${HOMEBREW_PREFIX}/bin/ghostty"
}

#! Set up Homebrew.
# Install Homebrew locally to enable downloading, building, and installing tools from source.
setupHomeBrew() {
	printf "\n> Installing Homebrew.\n"

	# TODO: Install Homebrew dependencies if inside a toolbox environment.
	# sudo apt-get update
	# sudo apt-get install build-essential procps curl file git --no-install-recommends
	#
	# Create the Homebrew prefix directory; required before tar extraction.
	mkdir -p "${HOMEBREW_PREFIX}/Homebrew"

	# Download a tarball of the `master` branch rather than cloning, because
	# git is not yet available (installed later via Brew).
	curl -L https://github.com/Homebrew/brew/archive/main.tar.gz -o "/tmp/homebrew.tar.gz"

	tar -xf "/tmp/homebrew.tar.gz" -C "${HOMEBREW_PREFIX}/Homebrew/" --strip-components=1

	# Symlink the dedicated brew binary into the Homebrew binary directory.
	mkdir -p "${HOMEBREW_PREFIX}/bin/"
	ln -s "${HOMEBREW_PREFIX}/Homebrew/bin/brew" "${HOMEBREW_PREFIX}/bin/"

	rm -f "/tmp/homebrew.tar.gz"
}

#! Update lock state.
# Update all lockfiles and other hard-coded versions used to install and manage third-party software referenced by this dotfile project.
updateLockState() {
	printf "\n> Updating lockfiles and hard-coded versions.\n"

	nvim --headless -c "lua vim.pack.update(nil, { force = true })" -c "qa!"

	# TODO: Extend to include lockfiles for fnm (Node.js version), Brew (Brewfile.lock), and pinned AppImage hashes.

	# TODO: Display a diff of changed lockfiles and prompt the user to confirm before committing.
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
