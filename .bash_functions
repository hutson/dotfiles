#!/usr/bin/env bash

#! Setup a local environment.
# Setup a local environment that contains all the tools and libraries needed for development work, and play.
setupEnvironment() {
	printf "\n> Removing %s directory.\n" "${HOMEBREW_PREFIX}"

	# Clear out our local system directory.
	if [ -d "${HOMEBREW_PREFIX}" ]; then
		rm -fr "${HOMEBREW_PREFIX}" &>/dev/null
	fi

	# Setup Brew.
	setupHomeBrew
	installBrewPackages
	installNodePackages
	brew cleanup -s

	nvim +PlugUpgrade +PlugInstall +PlugUpdate +PlugClean +TSUpdate +qa

	if [ "$(uname -n)" = "startopia" ]; then
		setupTilingWindowManager
	fi
}

#! Update environment.
# Update our development environment by installing the latest version of our desired tools.
updateEnvironment() {
	# Update Brew.
	brew update

	# Upgrade all Brew-installed packages.
	brew unlink util-linux # To work around `uuid.h no such file` error. See https://github.com/orgs/Homebrew/discussions/4899#discussioncomment-7564355
	brew upgrade
	brew link util-linux

	# Cleanup Brew installation.
	brew cleanup -s --prune=all

	# Update general tools.
	if [ "$(uname)" = "Darwin" ]; then
		installNodePackages
	fi

	nvim +PlugUpgrade +PlugInstall +PlugUpdate +PlugClean +TSUpdate +qa

	if [ "$(uname -n)" = "startopia" ]; then
		setupTilingWindowManager

		# Delete the `flatpak` directory and re-create it via the `repair` command, because `brew cleanup` deletes the directories in the `repo/` folder, though not the `config` file in that directory. Therefore, the directory ends up in a corrupted state.
		rm -rf ~/.linuxbrew/share/flatpak/repo/
		flatpak --user repair

		flatpak update -y --noninteractive
	fi
}

#! Setup HomeBrew.
# Install HomeBrew locally so that we can download, build, and install tools from source.
setupHomeBrew() {
	printf "\n> Installing HomeBrew.\n"

	# Create a local binary directory before any setup steps require its existence. It must exist for the tar extraction process to extract the contents of Brew into the `.local/` directory.
	mkdir -p "${HOMEBREW_PREFIX}/Homebrew"

	# Download an archive version of the #master branch of Brew to the local system for future extraction. We download an archive version of Brew, rather than cloning the #master branch, because we must assume that the local system does not have the `git` tool available (A tool that will be installed later using Brew).
	curl -L https://github.com/Homebrew/brew/archive/master.tar.gz -o "/tmp/homebrew.tar.gz"

	# Extract archive file into local system directory.
	tar -xf "/tmp/homebrew.tar.gz" -C "${HOMEBREW_PREFIX}/Homebrew/" --strip-components=1

	# Symlink the dedicated brew binary into our Homebrew binary directory.
	mkdir -p "${HOMEBREW_PREFIX}/bin/"
	ln -s "${HOMEBREW_PREFIX}/Homebrew/bin/brew" "${HOMEBREW_PREFIX}/bin/"

	rm -f "/tmp/homebrew.tar.gz"
}

#! Install packages via Brew.
# Install packages via Brew's `brew` CLI tool.
installBrewPackages() {
	if command -v brew &>/dev/null; then
		printf "\n> Installing Brew packages.\n"

		if [ "$(uname)" = "Darwin" ] || [ "$(uname -n)" = "startopia" ]; then
			# Install the latest Bash shell environment. This will give us access to the latest features in our primary work environment.
			brew install bash

			# Install bash-completion. This allows us to leverage bash completion scripts installed by our brew installed packages. Version @2 is required for Bash > 2.
			brew install bash-completion@2

			# Install ncdu, a command line tool for displaying disk usage information.
			brew install ncdu

			# Linter for shell scripts, including Bash.
			brew install shellcheck

			# Install shell script formatter.
			brew instal shfmt

			# Install Go compiler and development stack.
			brew install go
			brew install gopls # Language server for the Go language.

			# Install a CLI tool for managing Node interpreter versions within the current shell environment.
			brew install fnm
			eval "$(fnm env --use-on-cd)"

			# Install git, a distributed source code management tool.
			brew install git

			# Install the Large File Storage (LFS) git extension. The Large File Storage extension replaces large files that would normally be committed into the git repository, with a text pointer. Each revision of a file managed by the Large File Storage extension is stored server-side. Requires a remote git server with support for the Large File Storage extension.
			brew install git-lfs

			# Install command line text editor.
			brew install neovim
			brew install ripgrep                                                                                                                                                                        # Used by `telescope` for fast in-file searching.
			curl --location --output "${XDG_DATA_HOME}/nvim/site/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/ca0ae0a8b1bd6380caba2d8be43a2a19baf7dbe2/plug.vim # Library needed to support our plugin manager of choice for Neovim.

			# Fancy cross-shell command line prompt.
			brew install starship
		fi

		if [ "$(uname)" = "Darwin" ]; then
			# Install cross-platform terminal emulator.
			brew install wezterm

			# Install the Nerd Font patched Hack monspace font for our development environment.
			brew tap homebrew/cask-fonts
			brew install font-hack-nerd-font

			# Latest GNU core utilities, such as `rm`, `ls`, etc.
			brew install coreutils

			# Docker/container support.
			brew install colima
			brew install docker

			# Store Docker Hub credentials in the OSX Keychain for improved security.
			brew install docker-credential-helper

			# Install resource orchestration tool.
			brew install terraform
			brew install hashicorp/tap/terraform-ls # Language server.

			# A commandline first note taking tool.
			brew install nb

			brew install wget

			# Required to get a prompt for a security key pin when using GPG for SSH authentication on Mac devices.
			brew install pinentry-mac
			brew install gpg

			brew install yubico-yubikey-manager
			brew install firefox
			brew install gpg-suite
			brew install keepassxc
			brew install obs
			brew install rectangle

		elif [ "$(uname -n)" = "startopia" ]; then
			# Install cross-platform terminal emulator.
			brew install wez/wezterm-linuxbrew/wezterm

			# Install the Nerd Font patched Hack monspace font for our development environment.
			brew tap homebrew/linux-fonts
			brew install font-hack-nerd-font
			fc-cache -fv

			# Used to interact with the X11 system clipboard for Neovim.
			brew install xclip

			# Static site generator and build tool.
			brew install hugo

			# Tool for managing offline video archives.
			brew install yt-dlp
		# For packages that should only be installed server-side and not on a desktop/local system.
		else
			# Install terminal multiplexer if it does not already exist on the target system.
			if ! command -v tmux &>/dev/null; then
				brew install tmux
			fi
		fi
	else
		echo "ERROR: 'brew' is required for building and installing tools from source, but it's not available in your PATH. Please install 'brew' and ensure it's in your PATH. Then re-run 'installBrewPackages'."
	fi
}

#! Install NodeJS packages.
# Install NodeJS packages via `npm`.
installNodePackages() {
	if command -v fnm &>/dev/null; then
		printf "\n> Installing Node packages.\n"

		fnm install 22

		# Tool to update a markdown file, such as a `README.md` file, with a Table of Contents.
		npm install -g doctoc

		# Language server for the Bash language.

		# TODO: Switch this back to the Homebrew package `bash-language-server` as soon as we address the burden of needing to
		#				download and compile the NodeJS package, which takes a very very long time and considerable system resources.
		npm install -g bash-language-server

		# Update PATH to reflect the current location of Node packages, which may have changed if `fnm` installed a new version of Node or Npm.
		if command -v npm --version >/dev/null 2>&1; then
			local PATH
			PATH="$(npm -g bin):${PATH}"
			export PATH
		fi

	else
		echo "ERROR: 'fnm' is required for installing NodeJS packages, but it's not available in your PATH. Please install 'fnm' and ensure it's in your PATH. Then re-run 'installNodePackages'."
	fi
}

#! Setup tiling window manager on KDE.
# Setup a tiling window manager on a KDE desktop by extending KDE's existing KWin window manager using KDE's ability to load arbitrary scripts as plugins.
setupTilingWindowManager() {
	# Only install the tiling window manager on KDE.
	if command -v plasmapkg2 &>/dev/null; then
		local dirPriorToExe
		dirPriorToExe="$(pwd)"
		local tmpdir
		tmpdir="$(mktemp -d)"

		git clone https://github.com/kwin-scripts/kwin-tiling.git "${tmpdir}"

		cd "${tmpdir}" || exit

		# Download a fixed commit to install as our tiling window management script to minimize the chance of breaking changes.
		git checkout 51e51f4bb129dce6ab876d07cfd8bdb3506390e1

		if ! plasmapkg2 --type kwinscript -u .; then
			plasmapkg2 --type kwinscript -i .
		fi

		# Fix documented here - https://github.com/kwin-scripts/kwin-tiling/issues/79#issuecomment-311465357
		# Upstream KDE bug report - https://bugs.kde.org/show_bug.cgi?id=386509
		mkdir --parent "${HOMEBREW_PREFIX}/share/kservices5"
		ln --force --symbolic "${HOMEBREW_PREFIX}/share/kwin/scripts/kwin-script-tiling/metadata.desktop" "${HOMEBREW_PREFIX}/share/kservices5/kwin-script-tiling.desktop"

		cd "${dirPriorToExe}" || exit

		echo "Navigate to the KWin scripts manager to enable the 'kwinscript' script."
	fi
}

#! Find all file types in use and convert to standard types.
# Find all file types in use within a given directory and offer to convert files to a known set of standard file types, such as WAV to FLAC, using appropriate permissions (not globally readable).
checkAndConvert() {
	# TODO: Prompt user whether global permissions should be revoked from listed files.
	printf "\n> List of globally accessible files.\n"
	find . ! -type l \( -perm -o+r -or -perm -o+w -or -perm -o+x \) -print0 | xargs -0 ls -l

	## TODO: Rename all files to be all lower-case.
	# for i in $( ls | grep [A-Z] ); do mv -i $i `echo $i | tr 'A-Z' 'a-z'`; done
	# ls | sed -n 's/.*/mv "&" $(tr "[A-Z]" "[a-z]" <<< "&")/p' | bash

	# TODO: Convert some known file formats to an alternative, "open", file format.
	# To convert Office documents to ODF formats such as `.ods`.
	# lowriter --headless --convert-to ods *.xlsx
}

#! Compress a file or folder into one of many types of archive formats.
# Compress a file or folder into one of many types of archive formats. Compression is based on the archive type specified.
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

#! Extract multiple types of archive files.
# Extract multiple types of archive files. Extraction is based on the archive type, and whether they are compressed, and if so, the type of compression used.
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
