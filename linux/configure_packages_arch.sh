#!/usr/bin/env bash
# Configuring packages for a Linux system

sudo pacman -Syu --noconfirm

# Packages (distro-agnostic):

# Common
sudo pacman -S --noconfirm --needed bat # cat replacement with syntax highlighting, git integration
sudo pacman -S --noconfirm --needed cifs-utils # Common Internet File System utilities
sudo pacman -S --noconfirm --needed curl # command line tool for transferring data with URL syntax
sudo pacman -S --noconfirm --needed exa # Modern replacement for ls
sudo pacman -S --noconfirm --needed git # fast, scalable, distributed revision control system
sudo pacman -S --noconfirm --needed grc # Colorize logfiles and command output
sudo pacman -S --noconfirm --needed jq # lightweight and flexible command-line JSON processor
sudo pacman -S --noconfirm --needed lnav # ncurses-based log file viewer
sudo pacman -S --noconfirm --needed mosh # Mobile shell that supports roaming and intelligent local echo
sudo pacman -S --noconfirm --needed mtr # traceroute and ping in a single tool
sudo pacman -S --noconfirm --needed ncdu # NCurses Disk Usage
sudo pacman -S --noconfirm --needed ngrep # grep for network traffic
sudo pacman -S --noconfirm --needed ranger # caca-utils highlight atool w3m poppler-utils mediainfo # File manager with an ncurses frontend written in Python
sudo pacman -S --noconfirm --needed rlwrap # readline feature command line wrapper
sudo pacman -S --noconfirm --needed shellcheck # lint tool for shell scripts
sudo pacman -S --noconfirm --needed stow # I use it to manage my dotfiles symlinks
sudo pacman -S --noconfirm --needed tig # Text interface for Git repositories
sudo pacman -S --noconfirm --needed tmux # terminal multiplexer
sudo pacman -S --noconfirm --needed tree # displays an indented directory tree, in color
sudo pacman -S --noconfirm --needed universal-ctags # builds text indexes for source code files
sudo pacman -S --noconfirm --needed vim # Vi IMproved - enhanced vi editor
sudo pacman -S --noconfirm --needed wget # retrieves files from the web
sudo pacman -S --noconfirm --needed xsel # command line tool to access X clipboard and selection buffers
# Diagnostics
sudo pacman -S --noconfirm --needed atop # Monitor for system resources and process activity
sudo pacman -S --noconfirm --needed dstat # versatile resource statistics tool
sudo pacman -S --noconfirm --needed htop # interactive processes viewer
sudo pacman -S --noconfirm --needed iftop # displays bandwidth usage information on an network interface
sudo pacman -S --noconfirm --needed iotop # simple top-like I/O monitor
sudo pacman -S --noconfirm --needed lsof # Utility to list open files
sudo pacman -S --noconfirm --needed ltrace # Tracks runtime library calls in dynamically linked programs
sudo pacman -S --noconfirm --needed nethogs # Net top tool grouping bandwidth per process
sudo pacman -S --noconfirm --needed strace # System call tracer
sudo pacman -S --noconfirm --needed zoxide # Shell extension to easily jump to frequently accessed directories

# Packages (arch-specific):

sudo pacman -S --noconfirm --needed fd # Simple, fast and user-friendly alternative to find
sudo pacman -S --noconfirm --needed lazygit # terminal ui for git
sudo pacman -S --noconfirm --needed the_silver_searcher # very fast grep-like program, alternative to ack-grep
sudo pacman -S --noconfirm --needed starship # shell-agnostic prompt

# Packages (AUR):

yay -S --noconfirm git-extras # Extra commands for git
yay -S --noconfirm lazydocker # terminal ui for docker and docker-compose
yay -S --noconfirm ripgrep # Fast regex text searching tool for files (recursively), respects .gitignore
yay -S --noconfirm shfmt # shell parser, formatter, and interpreter
