#!/usr/bin/env bash
# Configuring packages for a Linux system

sudo pacman -Syu --noconfirm

# Packages (distro-agnostic):

# Common
sudo pacman -S --noconfirm bat # cat replacement with syntax highlighting, git integration
sudo pacman -S --noconfirm cifs-utils # Common Internet File System utilities
sudo pacman -S --noconfirm curl # command line tool for transferring data with URL syntax
sudo pacman -S --noconfirm git # fast, scalable, distributed revision control system
sudo pacman -S --noconfirm grc # Colorize logfiles and command output
sudo pacman -S --noconfirm jq # lightweight and flexible command-line JSON processor
sudo pacman -S --noconfirm lnav # ncurses-based log file viewer
sudo pacman -S --noconfirm mosh # Mobile shell that supports roaming and intelligent local echo
sudo pacman -S --noconfirm mtr # traceroute and ping in a single tool
sudo pacman -S --noconfirm ncdu # NCurses Disk Usage
sudo pacman -S --noconfirm ngrep # grep for network traffic
sudo pacman -S --noconfirm ranger # caca-utils highlight atool w3m poppler-utils mediainfo # File manager with an ncurses frontend written in Python
sudo pacman -S --noconfirm rlwrap # readline feature command line wrapper
sudo pacman -S --noconfirm shellcheck # lint tool for shell scripts
sudo pacman -S --noconfirm stow # I use it to manage my dotfiles symlinks
sudo pacman -S --noconfirm tig # Text interface for Git repositories
sudo pacman -S --noconfirm tmux # terminal multiplexer
sudo pacman -S --noconfirm tree # displays an indented directory tree, in color
sudo pacman -S --noconfirm universal-ctags # builds text indexes for source code files
sudo pacman -S --noconfirm vim # Vi IMproved - enhanced vi editor
sudo pacman -S --noconfirm wget # retrieves files from the web
sudo pacman -S --noconfirm xsel # command line tool to access X clipboard and selection buffers
# Diagnostics
sudo pacman -S --noconfirm atop # Monitor for system resources and process activity
sudo pacman -S --noconfirm dstat # versatile resource statistics tool
sudo pacman -S --noconfirm htop # interactive processes viewer
sudo pacman -S --noconfirm iftop # displays bandwidth usage information on an network interface
sudo pacman -S --noconfirm iotop # simple top-like I/O monitor
sudo pacman -S --noconfirm lsof # Utility to list open files
sudo pacman -S --noconfirm ltrace # Tracks runtime library calls in dynamically linked programs
sudo pacman -S --noconfirm nethogs # Net top tool grouping bandwidth per process
sudo pacman -S --noconfirm strace # System call tracer

# Packages (arch-specific):

sudo pacman -S --noconfirm lazygit # terminal ui for git
sudo pacman -S --noconfirm the_silver_searcher # very fast grep-like program, alternative to ack-grep

# Packages (AUR):

yay -S --noconfirm git-extras # Extra commands for git
yay -S --noconfirm lazydocker # terminal ui for docker and docker-compose
yay -S --noconfirm ripgrep # Fast regex text searching tool for files (recursively), respects .gitignore
yay -S --noconfirm shfmt # shell parser, formatter, and interpreter

# Non-packaged software:

dotrepos="$HOME/.repos"
mkdir -p "$dotrepos"

# FZF
if [ -d $dotrepos/fzf/.git ]; then
  git -C "$dotrepos/fzf" pull --prune
else
  git clone --depth 1 https://github.com/junegunn/fzf "$dotrepos/fzf"
fi
"$dotrepos/fzf/install" --key-bindings --completion --no-update-rc
