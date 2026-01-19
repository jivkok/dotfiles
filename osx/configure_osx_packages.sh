#!/usr/bin/env bash
# OSX packages

install_brew_package() {
  if [ -z "$1" ]; then
    echo "Package name not set."
    return
  fi

  local package="$1"
  local installed=$(brew list --versions "$package")

  if [ -z "$installed" ]; then
    brew install "$package"
  fi
}

install_cask_package() {
  local package="$1"
  local installed=$(brew list --versions --cask "$package")

  if [ -z "$installed" ]; then
    brew install --cask "$package"
  fi
}

install_mas_package() {
  if [ -z "$1" ]; then
    echo "Package name not set."
    return
  fi

  local package="$1"
  local installed=$(mas list | grep "$package")

  if [ -z "$installed" ]; then
    mas install "$package"
  fi
}

dotdir="$( cd "$( dirname "$0" )/.." && pwd )"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Configuring OSX packages ..."

# Install/update homebrew
if [ ! -f /opt/homebrew/bin/brew ]; then
  dot_trace "Installing Homebrew."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export PATH
else
  dot_trace "Updating Homebrew."
  brew update --quiet
fi

dot_trace "Updating existing brew/cask packages."
brew upgrade --quiet

dot_trace "Installing brew packages."

# GNU utilities (those that come with OS X are outdated).
# Don’t forget their paths to $PATH. Example for coreutils: $(brew --prefix coreutils)/libexec/gnubin
install_brew_package coreutils
install_brew_package binutils # FSF/GNU ld, ar, readelf, etc. for native development
install_brew_package findutils # GNU `find`, `locate`, `updatedb`, and `xargs`
install_brew_package moreutils # Collection of tools that nobody wrote when UNIX was young
install_brew_package gnu-indent # C code prettifier
install_brew_package gnu-sed # GNU implementation of the famous stream editor
install_brew_package gnu-tar # GNU version of the tar archiving utility
install_brew_package gnu-which # GNU implementation of which utility
install_brew_package gawk # GNU awk utility
install_brew_package gnutls # GNU Transport Layer Security (TLS) Library
install_brew_package gpatch # Apply a diff file to an original
install_brew_package grep # GNU grep, egrep and fgrep
install_brew_package gzip # Popular GNU data compression program
install_brew_package file-formula # Utility to determine file types
install_brew_package less # Pager program similar to more
install_brew_package m4 # Macro processing language
install_brew_package make # Utility for directing compilation
install_brew_package nano # Free (GNU) replacement for the Pico text editor
install_brew_package openssh # OpenBSD freely-licensed SSH connectivity tools
install_brew_package rsync # Utility that provides fast incremental file transfer
install_brew_package unzip # Extraction utility for .zip compressed archives
install_brew_package watch # Executes a program periodically
install_brew_package wdiff # Display word differences between text files
install_brew_package wget # Internet file retriever

# Bash
install_brew_package bash
install_brew_package bash-completion
# Switch to this Bash with:
# echo /usr/local/bin/bash | sudo tee -a /etc/shells
# chsh -s /usr/local/bin/bash

# Misc
install_brew_package ansible # Automate deployment, configuration, and upgrading
install_brew_package bat # cat-clone with syntax highlighting and Git integration
install_brew_package bfg # Remove large files or passwords from Git history like git-filter-branch
install_brew_package binwalk # Searches a binary image for embedded files and executable code
install_brew_package ccat # Like cat but displays content with syntax highlighting
install_brew_package cmake # Cross-platform make
install_brew_package diff-so-fancy # Improved diffs with diff-highlight and more
install_brew_package dns2tcp # TCP over DNS tunnel
install_brew_package dos2unix # Convert text between DOS, UNIX, and Mac formats
install_brew_package duti # Select default apps for documents and URL schemes on macOS
install_brew_package eza # Modern replacement for ls
install_brew_package ffmpeg # Play, record, convert, and stream audio and video
install_brew_package fd # Simple, fast and user-friendly alternative to find
install_brew_package git # Distributed revision control system
install_brew_package git-delta # Syntax-highlighting pager for git and diff output
install_brew_package git-extras # Small git utilities
install_brew_package graphviz # Graph visualization software from AT&T and Bell Labs
install_brew_package grc # Colorize logfiles and command output
install_brew_package htop # Improved top (interactive process viewer)
install_brew_package ifstat # Tool to report network interface bandwidth
install_brew_package iftop # Display an interface's bandwidth usage
install_brew_package imagemagick # Tools and libraries to manipulate images in many formats
install_brew_package jq # Lightweight and flexible command-line JSON processor
install_brew_package lazydocker # terminal ui for docker and docker-compose
install_brew_package lazygit # terminal ui for git
install_brew_package lnav # Curses-based tool for viewing and analyzing log files
install_brew_package lsof # Utility to list open files
install_brew_package lua # Powerful, lightweight programming language
install_brew_package lynx # Text-based web browser
install_brew_package m-cli # Swiss Army Knife for macOS
install_brew_package mas # Mac App Store command-line interface
install_brew_package miller # Like sed, awk, cut, join & sort for name-indexed data such as CSV
install_brew_package mtr # traceroute and ping in a single tool
install_brew_package mosh # Remote terminal application
install_brew_package ngrep # Network grep
install_brew_package ncdu # NCurses Disk Usage
install_brew_package nnn # Fast file browser
install_brew_package nmap # Port scanning utility for large networks
install_brew_package p7zip # 7-Zip (high compression file archiver) implementation
install_brew_package pandoc # markup converter
install_brew_package php # Scripting language generally used for the web
install_brew_package pigz # Parallel gzip
install_brew_package pngcheck # Print info and check PNG, JNG, and MNG files
install_brew_package pv # Monitor data's progress through a pipe
install_brew_package ranger # File browser. Extras: libcaca highlight atool lynx w3m elinks poppler transmission mediainfo exiftool
install_brew_package rename # Perl-powered file rename script with many helpful built-ins
install_brew_package restic # Fast, efficient, and secure backup program
install_brew_package ripgrep # Search tool like grep and The Silver Searcher
install_brew_package screenfetch # Generate ASCII art with terminal, shell, and OS info
install_brew_package shellcheck # Static analysis and lint tool, for (ba)sh scripts
install_brew_package shfmt # shell parser, formatter, and interpreter
install_brew_package socat # netcat on steroids
install_brew_package speedtest-cli # Command-line interface for https://speedtest.net bandwidth tests
install_brew_package ssh-copy-id # Add a public key to a remote machine's authorized_keys file
install_brew_package starship # cross-shell prompt
install_brew_package tcpflow # TCP flow recorder
install_brew_package tcpreplay # Replay saved tcpdump files at arbitrary speeds
install_brew_package tcptrace # Analyze tcpdump output
install_brew_package the_silver_searcher # Code-search similar to ack
install_brew_package tig # Text interface for Git repositories
install_brew_package tldr # Simplified and community-driven man pages
install_brew_package tmux # Terminal multiplexer
install_brew_package tree # Display directories as trees (with optional color/HTML output)
install_brew_package ucspi-tcp # Tools for building TCP client-server applications
install_brew_package universal-ctags --HEAD # ctags
install_brew_package unix2dos # Convert text between DOS, UNIX, and Mac formats
install_brew_package webkit2png # Create screenshots of webpages from the terminal
install_brew_package zoxide # Shell extension to easily jump to frequently accessed directories

# Previously used brew packages
# brew install ack # Search tool like grep, but optimized for programmers
# brew install asciinema # Record and share terminal sessions
# brew install cifer # Work on automating classical cipher cracking in C
# brew install exiv2 # EXIF and IPTC metadata manipulation library and tools
# brew install fasd # CLI tool for quick access to files and directories
# brew install foremost # Console program to recover files based on their headers and footers
# brew install fcrackzip # Zip password cracker
# brew install hashpump # Tool to exploit hash length extension attack
# brew install hydra # Network logon cracker which supports many services
# brew install john # Featureful UNIX password cracker
# brew install knock # Port-knock server
# brew install pt # Multi-platform code-search similar to ack and ag
# brew install rhino # JavaScript engine
# brew install sqlmap # Penetration testing for SQL injection and database servers
# brew install sshfs # File system client based on SSH File Transfer Protocol. Requires osxfuse
# brew install task # Feature-rich console based todo list manager - Task Warrior
# brew install vit # Front-end for Task Warrior
# brew install watch # Executes a program periodically, showing output fullscreen
# brew install xpdf # PDF viewer
# brew install xz # General-purpose data compression with high compression ratio
# brew install zopfli # New zlib (gzip, deflate) compatible compressor

dot_trace "Installing cask packages."

# browsers
install_cask_package brave-browser
install_cask_package google-chrome # brew reinstall google-chrome --no-quarantine
install_cask_package chromium
install_cask_package firefox
install_cask_package librewolf # brew reinstall librewolf --no-quarantine
install_cask_package duckduckgo
install_cask_package opera

# FUSE, requires reboot
# brew cask install osxfuse

# development
install_cask_package http-toolkit # capture http(s) traffic / web development proxy
install_cask_package iterm2 # terminal
install_cask_package kdiff3 # file/directory diff/merge
install_cask_package key-codes # key codes
install_cask_package p4v # file diff/merge
install_cask_package postman # http APIs (REST/SOAP/GraphQL) development
install_cask_package proxyman # capture http(s) traffic / web development proxy
install_cask_package sourcetree # Git gui
install_cask_package tableplus # relational databases (MySQL, PostgreSQL, SQLite, etc.) management
install_cask_package uncrustifyx # Source Code Beautifier for C-style languages
install_cask_package visual-studio-code # code/text editor
install_cask_package xbar # Put anything in your Mac OS X menu bar

# misc
install_cask_package appcleaner # apps cleaner
install_cask_package calibre # books
install_cask_package handbrake # video transcoder
install_cask_package joplin # evernote-like note-taking and web clipper
install_cask_package karabiner-elements # keyboard customization
install_cask_package keepassxc # passwords sync
install_cask_package makemkv # video formats converter/transcoder
install_cask_package mindforger # human mind inspired (Eisenhower matrix) personal knowledge management tool
install_cask_package obsidian # Knowledge base that works on top of a local folder of plain text Markdown files
install_cask_package omnidisksweeper # disk space utilization
# install_cask_package fertigt-slate # window management. Note: ARM binaries: https://github.com/fertigt/slate_arm64/releases/download/1.0/Slate.zip
install_cask_package suspicious-package # inspecting macOS installer packages
install_cask_package the-unarchiver # unarchive many archive formats
install_cask_package tunnelblick # OpenVPN client
install_cask_package vlc # media player
install_cask_package wireshark # network capture / monitor, depends on xquartz
install_cask_package xrg # System Monitor for OSX

# Developer-friendly quick-look plugins; see https://github.com/sindresorhus/quick-look-plugins
# brew cask install qlcolorcode qlstephen qlmarkdown quicklook-json qlprettypatch quicklook-csv betterzipql qlimagesize webpquicklook suspicious-package

# Previously used
# brew install --cask alfred # Spotlight-replacement, workflow automation
# brew install --cask brackets # code/text editor
# brew install --cask bwana # browser as man pager
# brew install --cask carbon-copy-cloner # disk copy
# brew install --cask ccmenu # CI server status
# brew install --cask cheatsheet # Hold the Command key longer in any app to get a list of keyboard shortcuts
# brew install --cask dash # documentation sets, code snippets, and text expansion
# brew install --cask dropbox # files sync
# brew install --cask evernote # notes sync
# brew install --cask etcher # burn images to USB drives & SD cards
# brew install --cask filezilla # file transfer
# brew install --cask flux # color adjustments
# brew install --cask geektool # OSX desktop customization
# brew install --cask gimp # imaging
# brew install --cask gisto # Github gists editor
# brew install --cask googleappengine # cloud apps
# brew install --cask homebrew/x11/meld # file/directory diff/merge
# brew install --cask itsycal # calendar in menu bar
# brew install --cask kaleidoscope # file/directory/image diff/merge
# brew install --cask loading # shows network activity per app
# brew install --cask murus # UI for OSX's Packet Firewall
# brew install --cask mysqlworkbench # MySQL management
# brew install --cask pacifist # OSX package files extractor
# brew install --cask packet-peeper # network monitor
# brew install --cask peakhour # network bandwidth monitoring and reporting
# brew install --cask pycharm # Python IDE
# brew install --cask snippet-edit # XCode snippets
# brew install --cask skype # chat
# brew install --cask spectacle # window management
# brew install --cask sublime-text # code/text editor
# brew install --cask superduper # disk duplication
# brew install --cask teamviewer # remote sharing
# brew install --cask transmission # Bittorrent client
# brew install --cask Ubersicht # desktop customization
# brew install --cask virtualbox # virtual machines
# brew install --cask xquartz # X11
# https://www.trankynam.com/atext and http://www.phraseexpress.com/ - text expansion. Note: Alfred also does text expansion

dot_trace "brew cleanup."
brew cleanup

dot_trace "Installing AppStore apps."

# AppStore apps:
install_mas_package 1044484672 # ApolloOne - Photo Video Viewer. RAW files viewer & EXIF editor
install_mas_package 1473079126 # Cleaner One: Disk Clean
install_mas_package 1295203466 # Microsoft Remote Desktop
install_mas_package 302584613 # Amazon Kindle
# mas install 937984704 # Amphetamine - keep your Mac awake
# mas install 576421334 # Converto - The Unit Converter
# mas install 442160987 # Flycut (Clipboard manager)

# Install these widget apps from the AppStore:
# nothing currently

dot_trace "Configuring OSX packages done."
