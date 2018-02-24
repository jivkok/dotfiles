#!/bin/bash
# Packages

sudo apt-get update

# Common
sudo apt-get install -y cifs-utils # Common Internet File System utilities
sudo apt-get install -y curl # command line tool for transferring data with URL syntax
sudo apt-get install -y dstat # versatile resource statistics tool
sudo apt-get install -y exuberant-ctags # build tag file indexes of source code definitions
sudo apt-get install -y git # fast, scalable, distributed revision control system
sudo apt-get install -y git-extras # Extra commands for git
sudo apt-get install -y gitk # fast, scalable, distributed revision control system (revision tree visualizer)
sudo apt-get install -y gitstats # statistics generator for git repositories
sudo apt-get install -y graphviz # rich set of graph drawing tools
sudo apt-get install -y jq # lightweight and flexible command-line JSON processor
sudo apt-get install -y libwww-perl # simple and consistent interface to the world-wide web
sudo apt-get install -y lnav # ncurses-based log file viewer
sudo apt-get install -y ngrep # grep for network traffic
sudo apt-get install -y mosh # Mobile shell that supports roaming and intelligent local echo
sudo apt-get install -y python-pip # alternative Python package installer
sudo apt-get install -y python-pygments # syntax highlighting package written in Python
sudo apt-get install -y ranger # caca-utils highlight atool w3m poppler-utils mediainfo # File manager with an ncurses frontend written in Python
sudo apt-get install -y rlwrap # readline feature command line wrapper
sudo apt-get install -y screenfetch # Bash Screenshot Information Tool. Fetches system/theme information in terminal
sudo apt-get install -y silversearcher-ag # very fast grep-like program, alternative to ack-grep
sudo apt-get install -y shellcheck # lint tool for shell scripts
sudo apt-get install -y tmux # terminal multiplexer
sudo apt-get install -y tree # displays an indented directory tree, in color
sudo apt-get install -y vim # Vi IMproved - enhanced vi editor
sudo apt-get install -y wget # retrieves files from the web
sudo apt-get install -y xsel # command line tool to access X clipboard and selection buffers

# FZF
if [ -d $HOME/.fzf/.git ]; then
  git -C "$HOME/.fzf" pull --prune
else
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
fi
"$HOME/.fzf/install" --key-bindings --completion --no-update-rc

# Dev
sudo apt-get install -y libxml2-dev # Development files for the GNOME XML library
sudo apt-get install -y libxslt1-dev # XSLT 1.0 processing library - development kit
sudo apt-get install -y python-dev # header files and a static library for Python (default)

# Diagnostics
sudo apt-get install -y atop # Monitor for system resources and process activity
# sudo apt-get install -y collectl # Utility to collect Linux performance data
sudo apt-get install -y htop # interactive processes viewer
sudo apt-get install -y iftop # displays bandwidth usage information on an network interface
sudo apt-get install -y iotop # simple top-like I/O monitor
sudo apt-get install -y lsof # Utility to list open files
sudo apt-get install -y ltrace # Tracks runtime library calls in dynamically linked programs
sudo apt-get install -y nethogs # Net top tool grouping bandwidth per process
# sudo apt-get install -y ntop # display network usage in web browser
sudo apt-get install -y secure-delete # tools to wipe files, free disk space, swap and memory
sudo apt-get install -y strace # System call tracer

# TaskWarrior
sudo apt-get install -y task # feature-rich console based todo list manager - transitional package
sudo apt-get install -y vit # full-screen terminal interface for Taskwarrior

sudo apt-get clean
sudo apt-get autoremove
