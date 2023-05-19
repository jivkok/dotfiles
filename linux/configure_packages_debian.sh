#!/usr/bin/env bash
# Configuring packages for a Linux system

sudo apt-get update -y --fix-missing

# Packages (distro-agnostic):

# Common
sudo apt-get install -y bat # cat replacement with syntax highlighting, git integration
sudo apt-get install -y cifs-utils # Common Internet File System utilities
sudo apt-get install -y curl # command line tool for transferring data with URL syntax
sudo apt-get install -y exa # Modern replacement for ls
sudo apt-get install -y git # fast, scalable, distributed revision control system
sudo apt-get install -y grc # Colorize logfiles and command output
sudo apt-get install -y jq # lightweight and flexible command-line JSON processor
sudo apt-get install -y lnav # ncurses-based log file viewer
sudo apt-get install -y mosh # Mobile shell that supports roaming and intelligent local echo
sudo apt-get install -y mtr # traceroute and ping in a single tool
sudo apt-get install -y ncdu # NCurses Disk Usage
sudo apt-get install -y ngrep # grep for network traffic
sudo apt-get install -y ranger # caca-utils highlight atool w3m poppler-utils mediainfo # File manager with an ncurses frontend written in Python
sudo apt-get install -y rlwrap # readline feature command line wrapper
sudo apt-get install -y shellcheck # lint tool for shell scripts
sudo apt-get install -y stow # I use it to manage my dotfiles symlinks
sudo apt-get install -y tig # Text interface for Git repositories
sudo apt-get install -y tmux # terminal multiplexer
sudo apt-get install -y tree # displays an indented directory tree, in color
sudo apt-get install -y universal-ctags # builds text indexes for source code files
sudo apt-get install -y vim # Vi IMproved - enhanced vi editor
sudo apt-get install -y wget # retrieves files from the web
sudo apt-get install -y xsel # command line tool to access X clipboard and selection buffers
# Diagnostics
sudo apt-get install -y atop # Monitor for system resources and process activity
sudo apt-get install -y dstat # versatile resource statistics tool
sudo apt-get install -y htop # interactive processes viewer
sudo apt-get install -y iftop # displays bandwidth usage information on an network interface
sudo apt-get install -y iotop # simple top-like I/O monitor
sudo apt-get install -y lsof # Utility to list open files
sudo apt-get install -y ltrace # Tracks runtime library calls in dynamically linked programs
sudo apt-get install -y nethogs # Net top tool grouping bandwidth per process
sudo apt-get install -y strace # System call tracer
sudo apt-get install -y zoxide # Shell extension to easily jump to frequently accessed directories

# Packages (debian-specific):

sudo apt-get install -y fd-find # Simple, fast and user-friendly alternative to find
sudo apt-get install -y git-extras # Extra commands for git
sudo apt-get install -y ripgrep # Fast regex text searching tool for files (recursively), respects .gitignore
sudo apt-get install -y silversearcher-ag # very fast grep-like program, alternative to ack-grep

# Packages (Snap):

sudo snap install starship --edge # shell-agnostic prompt

# Go (debian-specific):

if command -V go >/dev/null 2>&1; then
go install github.com/jesseduffield/lazygit # terminal ui for git
go install github.com/jesseduffield/lazydocker # terminal ui for docker and docker-compose
go install mvdan.cc/sh/v3/cmd/shfmt # shell parser, formatter, and interpreter
fi
