#!/usr/bin/env bash

set -u

if [ "$(uname)" = "Darwin" ]; then
	# Prompt the user once before removing any file.
	alias rm='rm -i'
else
	# Do not allow deletion of content at the root level, /, and prompt the user once before removing more than three files or when removing files and directories recursively.
	alias rm='rm -I -v --preserve-root'
fi

# Enable common command confirmations with additional verbosity.
alias mv='mv -iv'
alias cp='cp -iv'
alias ln='ln -i'

# Enable color support for those GNU tools that support colorized output.
if command -v dircolors &>/dev/null; then
	# Check if user has a dircolors database (a file that maps file types, and file permissions, to colors). If the user has such a file, then instruct dircolors to use that file to map Bash color commands to the desired colors.
	if [ -f "${HOME}/.dircolors" ]; then
		eval "$(dircolors --bourne-shell "${HOME}/.dircolors")"
	else
		eval "$(dircolors --bourne-shell)"
	fi

	alias ip='ip --color=auto'
	alias ls='ls --color=auto'
	alias dir='dir --color=auto'
	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
fi

# List content, including hidden files and folders, of a directory in long format.
alias ll='ls -A -F -b -h -l -v --time-style=long-iso'

# Enable a traditional login shell when using sudo or su.
alias root='sudo -i'
alias su='sudo -i'

# Clear out the bash history and clear the screen.
alias scram='history -c; clear; /usr/bin/env rm -rf ${XDG_DATA_HOME}/nvim/shada/ ${XDG_DATA_HOME}/nvim/undo/; /usr/bin/env rm -rf ${XDG_CACHE_HOME}/'

# Find the top 5 largest files within the current, and sub, directories.
alias findbig='find . -type f -exec ls -lha {} \; | sort --stable --parallel=2 -t" " -k5rh | head -5'

# Quickly find and print the top five processes consuming CPU cycles.
alias pscpu='ps aux | sort --stable --parallel=2 -k3rh | head -n 5'

# Quickly find and print the top five processes consuming memory.
alias psmem='ps aux | sort --stable --parallel=2 -k4rh | head -n 5'

# Show a tree view of all processes owned by the current user.
alias processes='ps xf'

# Update system packages and local packages through the use of a single command.
alias update='updateSystem && updateEnvironment'

# Update system packages.
alias updateSystem='sudo apt update && sudo apt full-upgrade && sudo apt autoremove'

# Reset our GPG environment to work with a different Yubikey (One Yubikey was removed from the system and another Yubikey key was plugged in.)
alias yubiset='rm -rf ~/.gnupg/private-keys-v1.d/ && gpgconf --kill gpg-agent && gpgconf --launch gpg-agent'

# List file extensions in use, starting at the current working directory and searching recursively.
alias fileExtensions='find . -type f | egrep -i -E -o "\.{1}\w*$" | sort | uniq -c | sort -n'

# Convert each zip file in the current, and sub, directories to a compressed Tar archive.
alias convertDirectoryZips='export -f convertZip && find . -type f -name "*.zip" -not -path "*/.*" -print | xargs -I % bash -c "convertZip \"%\""'

# Create a personal copy of a DVD onto my primary device as backup in case the legally acquired disk is lost or destroyed.
alias backupMyDVD='dvdbackup --mirror --input /dev/dvd --output ~/Videos/ --progress --verbose'
