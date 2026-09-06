# Install the latest Bash shell for access to modern features.
brew "bash"

# Install bash-completion to leverage bash completion scripts installed by our brew-installed packages. Version @2 is required for Bash > 2.
brew "bash-completion@2"

# Install ncdu, a command-line tool for displaying disk usage information.
brew "ncdu"

# Output file contents with syntax highlighting and Git integration.
brew "bat"

# Install Git version control.
brew "git"
brew "git-lfs" if OS.mac? # Install Git LFS for managing large binary files via text pointers. Requires a remote Git server with LFS support.

# Install command-line text editor.
brew "neovim"
brew "ripgrep"

# Language Servers
brew "marksman" # Language server for Markdown.
brew "lua-language-server" # Language server for Lua.
brew "bash-language-server" # Language server for Bash.
brew "gopls" # Language server for Go.
brew "ansible-language-server" # Language server for Ansible.
brew "terraform-ls" if OS.mac? # Language server for Terraform.

# Linters and Formatters
brew "shellcheck" # Linter for shell scripts, including Bash.
brew "shfmt" # Install shell script formatter.
brew "hadolint" # Linter for Containerfiles.
brew "yamllint" # Linter for YAML files.

# Fancy cross-shell command-line prompt.
brew "starship"

# Static site generator and build tool.
brew "hugo" if OS.linux?

# Interactive command line harness for working with LLMs.
brew "opencode"

# Tool for managing offline video archives.
brew "yt-dlp" if OS.linux?

# Install cross-platform terminal emulator.
brew "ghostty" if OS.mac?

# Latest GNU core utilities, such as `rm`, `ls`, etc.
brew "coreutils" if OS.mac?

# Docker/container support.
brew "colima" if OS.mac?
brew "docker" if OS.mac?
brew "docker-credential-helper" if OS.mac? # Store Docker Hub credentials in the macOS Keychain for improved security.

# Install Go compiler and development stack.
brew "go" if OS.mac?

# Install convinence tool for downloading Internet resources including Ghostty AppImage.
brew "wget" if OS.mac?

# Install resource orchestration tool.
brew "terraform" if OS.mac?

# Required to get a prompt for a security key PIN when using GPG for SSH authentication on Mac devices.
cask "pinentry-mac", greedy: true if OS.mac?
cask "gpg", greedy: true if OS.mac?

# Other desktop application on MacOS.
cask "yubico-authenticator", greedy: true if OS.mac?
cask "firefox@esr", greedy: true if OS.mac?
cask "gpg-suite", greedy: true if OS.mac?
cask "keepassxc", greedy: true if OS.mac?
cask "obs", greedy: true if OS.mac?
