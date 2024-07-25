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

If on Linux, navigate to the [Homebrew for Linux](https://docs.brew.sh/Homebrew-on-Linux) website and install all the required packages for your Linux distribution. A few of the tools installed by this `dotfiles` project require libraries and system-level packages. For Debian-based systems, please ensure you install (`sudo apt install [package] --no-install-recommends`) the following packages in addition to the packages required by Homebrew.

- `python3-distutils` - Needed for `nb`. (`distutils` is deprecated and will be removed from Python in version 3.12 - https://docs.python.org/3/whatsnew/3.10.html#distutils-deprecated)
- `g++-multilib` - Needed for `neovim`.

If using macOS, navigate to the [Homebrew](https://docs.brew.sh/Installation) website and install all the required packages for your Linux distribution. Then run `git` on the Terminal once, and follow the instructions to install Apple's Developer Tools. This will ensure `git` is available for use by Homebrew, when we use Homebrew to install both command line tools and applications.

Once deployed the `${HOME}/.profile` script will need to be sourced, just once, to expose the scripts contained within the dotfiles repository. To source the profile script run the following command:

```bash
source ~/.profile
```

On macOS, run `gpg --import <public key>` to import the GPG public key used for signing operations, such as signing Git commits.
