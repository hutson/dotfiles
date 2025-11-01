#!/usr/bin/env bash

set -u

# BEGIN HISTORY

# Don't push duplicate lines, or lines starting with a space, in the history. The second ignore condition allows you to execute commands with a leading space, thereby instructing Bash to not place them into history.
HISTCONTROL=ignoreboth

# For setting history length see HISTSIZE and HISTFILESIZE.
HISTSIZE=32768
HISTFILESIZE=${HISTSIZE:-}

# Include date and timestamps in history output.
HISTTIMEFORMAT='%F %T '

# Ignore certain commands given by the user, for the sake of history, such that they don't show up in Bash history.
HISTIGNORE="ls:bg:fg:history:exit"

# Append command to the bash command history file instead of overwriting it.
shopt -s histappend

# Append command to the history file after every display of the command prompt, instead of after terminating the session (the current shell).
# We no longer reload the contents of the history file into the history list (which is kept in memory). By reloading the history file (history -r) after appending commands to the file, we could have loaded history saved by other sessions currently running. However, that can cause commands from multiple sessions to intermix, making it difficult to re-produce your actions within the current session by following the command history in a linear fashion.
PROMPT_COMMAND='history -a'

# END HISTORY

# Correct minor spelling errors in a `cd` command; such as transposed, missing, or extra, characters without the need for retyping.
shopt -s cdspell

# Correct minor spelling errors in when completing a directory path; such as transposed, missing, or extra, characters without the need for retyping.
shopt -s dirspell
shopt -s direxpand

# Check the window size after each command and, if necessary update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Source the Brew bash completion initialization script if it exists, otherwise, just source each tool's completion script.
if type brew &>/dev/null; then
	if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
		# Ignoring ShellCheck issue because it is not possible to know where `HOMEBREW_PREFIX` points to ahead of time.
		# shellcheck source=/dev/null
		source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
	else
		for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
			if [[ -r "$COMPLETION" ]]; then
				# Ignoring ShellCheck issue because it is not possible to know every file in `bash_completion.d/` that will be sourced from here.
				# shellcheck source=/dev/null
				source "${COMPLETION}"
			fi
		done
	fi
fi

# Execute `fnm` to configure our local environment to allow installation of Node versions.
if command -v fnm >/dev/null 2>&1; then
	eval "$(fnm env)"
fi

# Execute `starship` to configure our fancy cross-shell command line prompt.
if command -v starship >/dev/null 2>&1; then
	eval "$(starship init bash)"
fi

# Source our custom shell aliases. All custom shell aliases should be in this external file rather than cluttering up this file.
if [ -f "${HOME}/.bash_aliases" ]; then
	source "${HOME}/.bash_aliases"
fi

# Source our custom bash functions.
if [ -f "${HOME}/.bash_functions" ]; then
	source "${HOME}/.bash_functions"
fi
