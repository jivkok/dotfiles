#!/usr/bin/env bash
# Configuring packages for a Linux system

sudo apt-get update -y --fix-missing -qq && sudo apt-get upgrade -y -qq

# Packages (distro-agnostic):

# Common
sudo apt-get install -y -qq bat # cat replacement with syntax highlighting, git integration
sudo apt-get install -y -qq cifs-utils # Common Internet File System utilities
sudo apt-get install -y -qq curl # command line tool for transferring data with URL syntax
sudo apt-get install -y -qq eza # Modern replacement for ls
sudo apt-get install -y -qq git # fast, scalable, distributed revision control system
sudo apt-get install -y -qq grc # Colorize logfiles and command output
sudo apt-get install -y -qq jq # lightweight and flexible command-line JSON processor
sudo apt-get install -y -qq lnav # ncurses-based log file viewer
sudo apt-get install -y -qq mosh # Mobile shell that supports roaming and intelligent local echo
sudo apt-get install -y -qq mtr # traceroute and ping in a single tool
sudo apt-get install -y -qq ncdu # NCurses Disk Usage
sudo apt-get install -y -qq ngrep # grep for network traffic
sudo apt-get install -y -qq ranger # caca-utils highlight atool w3m poppler-utils mediainfo # File manager with an ncurses frontend written in Python
sudo apt-get install -y -qq rlwrap # readline feature command line wrapper
sudo apt-get install -y -qq shellcheck # lint tool for shell scripts
sudo apt-get install -y -qq stow # I use it to manage my dotfiles symlinks
sudo apt-get install -y -qq tig # Text interface for Git repositories
sudo apt-get install -y -qq tmux # terminal multiplexer
sudo apt-get install -y -qq tree # displays an indented directory tree, in color
sudo apt-get install -y -qq universal-ctags # builds text indexes for source code files
sudo apt-get install -y -qq vim # Vi IMproved - enhanced vi editor
sudo apt-get install -y -qq wget # retrieves files from the web
sudo apt-get install -y -qq xsel # command line tool to access X clipboard and selection buffers
# Diagnostics
sudo apt-get install -y -qq atop # Monitor for system resources and process activity
sudo apt-get install -y -qq dstat # versatile resource statistics tool
sudo apt-get install -y -qq htop # interactive processes viewer
sudo apt-get install -y -qq iftop # displays bandwidth usage information on an network interface
sudo apt-get install -y -qq iotop # simple top-like I/O monitor
sudo apt-get install -y -qq lsof # Utility to list open files
sudo apt-get install -y -qq ltrace # Tracks runtime library calls in dynamically linked programs
sudo apt-get install -y -qq nethogs # Net top tool grouping bandwidth per process
sudo apt-get install -y -qq strace # System call tracer
sudo apt-get install -y -qq zoxide # Shell extension to easily jump to frequently accessed directories

# Packages (debian-specific):

sudo apt-get install -y -qq fd-find # Simple, fast and user-friendly alternative to find
sudo apt-get install -y -qq git-extras # Extra commands for git
sudo apt-get install -y -qq ripgrep # Fast regex text searching tool for files (recursively), respects .gitignore
sudo apt-get install -y -qq silversearcher-ag # very fast grep-like program, alternative to ack-grep

# Go (debian-specific):

if command -V go >/dev/null 2>&1; then
go install github.com/jesseduffield/lazygit # terminal ui for git
go install github.com/jesseduffield/lazydocker # terminal ui for docker and docker-compose
go install mvdan.cc/sh/v3/cmd/shfmt # shell parser, formatter, and interpreter
fi

# Non-packaged software (debian-specific):

# Starship: shell-agnostic prompt
if command -v starship >/dev/null 2>&1; then
  current_version=$(starship --version | head -n 1 | awk '{print $2}')
  latest_version=$(curl -s https://api.github.com/repos/starship/starship/releases/latest | jq ".tag_name" | tr -d 'v"')
  if [ "$current_version" != "$latest_version" ]; then
    echo "Starship's current version ($current_version) is different than latest ($latest_version). Installing it."
    install_starship=1
  else
    echo "Starship's current version ($current_version) is latest."
    install_starship=0
  fi
else
  echo "Starship is not installed. Installing it."
  install_starship=1
fi

if [ "$install_starship" = "1" ]; then
  curl -sS https://starship.rs/install.sh | sudo sh -s -- --yes
fi
