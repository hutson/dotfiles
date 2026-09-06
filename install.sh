#!/usr/bin/env bash

set -euf -o pipefail

# This file exists to install a minimum shell environment within a Dev Container environment.
# The user environment should only contain those aliases, tools, and configuration, needed to
# simplify the user's experience. No tools should be installed that might conflict with the
# tooling pre-installed by the Dev Container environment responsible for building and testing
# the given project.

cat <<- 'EOF' > "${XDG_CONFIG_HOME}/Brewfile"
	brew "opencode"
	brew "starship"
EOF

bash deploy.sh
source ~/.bash_functions
setupHomeBrew
brew bundle
