# dotfiles

This repository contains a collection of configuration files used by various tools to establish expected, and desired, functionality. These dotfiles are predominately written for tools used in a POSIX-compliant shell environment.

## Installation

Installation is as simple as copying these files into your home directory, or extracting a copy of the repository into a suitable location and then creating symlinks from the repository files into your home directory.

First, pull down, and then extract, a copy of the repository into a hidden dotfiles directory.

```bash
curl -L https://codeberg.org/hutson/dotfiles/archive/main.zip -o "/tmp/dotfiles.zip"
unzip /tmp/dotfiles.zip && mv dotfiles .dotfiles
rm "/tmp/dotfile.zip"
```

Navigate into the `${HOME}/.dotfiles` directory. Once there, run the deployment script to symlink the files into your home directory. The symbolic links will have names matching the names of the files in the repository.

```bash
cd ~/.dotfiles
bash deploy.sh
```

If on Linux, navigate to the [Homebrew for Linux](https://docs.brew.sh/Homebrew-on-Linux) website and install all the required packages for your Linux distribution.

Once deployed the `${HOME}/.profile` script will need to be sourced, just once, to expose the scripts contained within the dotfiles repository. To source the profile script run the following command:

```bash
source ~/.profile
```

Run `gpg --import <public key>` to import the GPG public key used for signing operations, such as signing Git commits.

## Development

To test your changes, run the test script from inside the Dev Container, which provides all required linting tools:

```bash
bash .tools/test.sh
```

Alternatively, run the tests from the host without entering the Dev Container by delegating to Devsy, which builds the project's devcontainer, runs the command inside it, and tears it down afterwards:

```bash
devsy ci . -- bash .tools/test.sh
```
