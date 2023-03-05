#!/usr/bin/env bash
# Homebrew packages

# Install homebrew
if [ ! -f /usr/local/bin/brew ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ask for the administrator password upfront.
sudo -v
# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

brew update
brew upgrade

# Terminal utilities

# Install GNU utilities (those that come with OS X are outdated).
# Don’t forget their paths to $PATH. Example for coreutils: $(brew --prefix coreutils)/libexec/gnubin
brew install coreutils
rm -f /usr/local/bin/sha256sum && ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum
brew install binutils # FSF/GNU ld, ar, readelf, etc. for native development
brew install findutils # GNU `find`, `locate`, `updatedb`, and `xargs`
brew install moreutils # Collection of tools that nobody wrote when UNIX was young
brew install gnu-indent # C code prettifier
brew install gnu-sed # GNU implementation of the famous stream editor
brew install gnu-tar # GNU version of the tar archiving utility
brew install gnu-which # GNU implementation of which utility
brew install gawk # GNU awk utility
brew install gdb # GNU debugger
brew install gnutls # GNU Transport Layer Security (TLS) Library
brew install gpatch # Apply a diff file to an original
brew install grep # GNU grep, egrep and fgrep
brew install gzip # Popular GNU data compression program
brew install file-formula # Utility to determine file types
brew install less # Pager program similar to more
brew install m4 # Macro processing language
brew install make # Utility for directing compilation
brew install nano # Free (GNU) replacement for the Pico text editor
brew install openssh # OpenBSD freely-licensed SSH connectivity tools
brew install rsync # Utility that provides fast incremental file transfer
brew install unzip # Extraction utility for .zip compressed archives
brew install watch # Executes a program periodically
brew install wdiff # Display word differences between text files
brew install wget # Internet file retriever

# Install latest Bash
brew install bash
brew install bash-completion
# Switch to this Bash with:
# echo /usr/local/bin/bash | sudo tee -a /etc/shells
# chsh -s /usr/local/bin/bash

# Packages
brew install bat # cat-clone with syntax highlighting and Git integration
brew install bfg # Remove large files or passwords from Git history like git-filter-branch
brew install binwalk # Searches a binary image for embedded files and executable code
brew install ccat # Like cat but displays content with syntax highlighting
brew install cmake # Cross-platform make
brew install dns2tcp # TCP over DNS tunnel
brew install dos2unix # Convert text between DOS, UNIX, and Mac formats
brew install duti # Select default apps for documents and URL schemes on macOS
brew install exa # Modern replacement for ls
brew install ffmpeg # Play, record, convert, and stream audio and video
brew install fdfind # Simple, fast and user-friendly alternative to find
brew install fzf # Command-line fuzzy finder
[ -f /usr/local/opt/fzf/install ] && /usr/local/opt/fzf/install --key-bindings --completion --no-update-rc
brew install git # Distributed revision control system
brew install git-extras # Small git utilities
brew install graphviz # Graph visualization software from AT&T and Bell Labs
brew install grc # Colorize logfiles and command output
brew install htop-osx # Improved top (interactive process viewer)
brew install ifstat # Tool to report network interface bandwidth
brew install iftop # Display an interface's bandwidth usage
brew install imagemagick # Tools and libraries to manipulate images in many formats
brew install jq # Lightweight and flexible command-line JSON processor
brew install lazydocker # terminal ui for docker and docker-compose
brew install lazygit # terminal ui for git
brew install lnav # Curses-based tool for viewing and analyzing log files
brew install lsof # Utility to list open files
brew install lua # Powerful, lightweight programming language
brew install lynx # Text-based web browser
brew install m-cli # Swiss Army Knife for macOS
brew install mas # Mac App Store command-line interface
brew install miller # Like sed, awk, cut, join & sort for name-indexed data such as CSV
brew install mtr # traceroute and ping in a single tool
brew install mobile-shell # Remote terminal application
brew install ngrep # Network grep
brew install ncdu # NCurses Disk Usage
brew install nnn # Fast file browser
brew install nmap # Port scanning utility for large networks
brew install p7zip # 7-Zip (high compression file archiver) implementation
brew install pandoc # markup converter
brew install php # Scripting language generally used for the web
brew install pigz # Parallel gzip
brew install pngcheck # Print info and check PNG, JNG, and MNG files
brew install pv # Monitor data's progress through a pipe
brew install ranger # File browser. Extras: libcaca highlight atool lynx w3m elinks poppler transmission mediainfo exiftool
brew install rename # Perl-powered file rename script with many helpful built-ins
brew install ripgrep # Search tool like grep and The Silver Searcher
brew install screenfetch # Generate ASCII art with terminal, shell, and OS info
brew install shellcheck # Static analysis and lint tool, for (ba)sh scripts
brew install shfmt # shell parser, formatter, and interpreter
brew install socat # netcat on steroids
brew install speedtest_cli # Command-line interface for https://speedtest.net bandwidth tests
brew install ssh-copy-id # Add a public key to a remote machine's authorized_keys file
brew install tcpflow # TCP flow recorder
brew install tcpreplay # Replay saved tcpdump files at arbitrary speeds
brew install tcptrace # Analyze tcpdump output
brew install the_silver_searcher # Code-search similar to ack
brew install tig # Text interface for Git repositories
brew install tldr # Simplified and community-driven man pages
brew install tmux # Terminal multiplexer
brew install tree # Display directories as trees (with optional color/HTML output)
brew install ucspi-tcp # Tools for building TCP client-server applications
brew install --HEAD universal-ctags/universal-ctags/universal-ctags # ctags
brew install unix2dos # Convert text between DOS, UNIX, and Mac formats
brew install webkit2png # Create screenshots of webpages from the terminal

# Vim
brew install vim
brew install neovim

# Remove outdated versions from the cellar.
brew cleanup

# Previously used
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

# GUI apps

# browsers
brew install --cask google-chrome
brew install --cask chromium
brew install --cask firefox
brew install --cask opera

# FUSE, requires reboot
# brew cask install osxfuse

# development
brew install --cask bitbar # Put anything in your Mac OS X menu bar
# brew install --cask bwana # browser as man pager
# brew install --cask dash # documentation sets, code snippets, and text expansion
brew install --cask filezilla # file transfer
brew install --cask gimp # imaging
brew install --cask http-toolkit # capture http(s) traffic / web development proxy
brew install --cask iterm2 # terminal
# brew install --cask kaleidoscope # file/directory/image diff/merge
brew install --cask kdiff3 # file/directory diff/merge
brew install --cask key-codes # key codes
# brew install --cask mysqlworkbench # MySQL management
brew install --cask p4merge # file diff/merge
brew install --cask postman # http APIs (REST/SOAP/GraphQL) development
brew install --cask proxyman # capture http(s) traffic / web development proxy
# brew install --cask pycharm # Python IDE
# brew install --cask snippet-edit # XCode snippets
brew install --cask sourcetree # Git gui
brew install --cask sublime-text # code/text editor
brew install --cask tableplus # relational databases (MySQL, PostgreSQL, SQLite, etc.) management
brew install --cask uncrustifyx # Source Code Beautifier for C-style languages
brew install --cask virtualbox # virtual machines
brew install --cask visual-studio-code # code/text editor

# other
brew install --cask appcleaner # apps cleaner
brew install --cask calibre # books
brew install --cask cheatsheet # Hold the Command key longer in any app to get a list of keyboard shortcuts
brew install --cask evernote # notes sync
brew install --cask etcher # burn images to USB drives & SD cards
brew install --cask flux # color adjustments
brew install --cask handbrake # video transcoder
brew install --cask itsycal # calendar in menu bar
brew install --cask joplin # evernote-like note-taking and web clipper
brew install --cask karabiner-elements # keyboard customization
brew install --cask keepassxc # passwords sync
brew install --cask kindle # books
brew install --cask makemkv # video formats converter/transcoder
brew install --cask mindforger # human mind inspired (Eisenhower matrix) personal knowledge management tool
brew install --cask omnidisksweeper # disk space utilization
brew install --cask pacifist # OSX package files extractor
brew install --cask packet-peeper # network monitor
brew install --cask skype # chat
brew install --cask slate # window management
brew install --cask suspicious-package # inspecting macOS installer packages
brew install --cask the-unarchiver # unarchive many archive formats
brew install --cask tunnelblick # OpenVPN client
brew install --cask vlc # media player
brew install --cask wireshark # network capture / monitor, depends on xquartz
brew install --cask xrg # System Monitor for OSX
brew install --cask zenmap # nmap GUI

# Developer-friendly quick-look plugins; see https://github.com/sindresorhus/quick-look-plugins
# brew cask install qlcolorcode qlstephen qlmarkdown quicklook-json qlprettypatch quicklook-csv betterzipql qlimagesize webpquicklook suspicious-package

# Used in the past
# brew install --cask alfred # Spotlight-replacement, workflow automation
# brew install --cask brackets # code/text editor
# brew install --cask carbon-copy-cloner # disk copy
# brew install --cask ccmenu # CI server status
# brew install --cask dropbox # files sync
# brew install --cask geektool # OSX desktop customization
# brew install --cask gisto # Github gists editor
# brew install --cask googleappengine # cloud apps
# brew install --cask homebrew/x11/meld # file/directory diff/merge
# brew install --cask loading # shows network activity per app
# brew install --cask murus # UI for OSX's Packet Firewall
# brew install --cask peakhour # network bandwidth monitoring and reporting
# brew install --cask spectacle # window management
# brew install --cask superduper # disk duplication
# brew install --cask teamviewer # remote sharing
# brew install --cask transmission # Bittorrent client
# brew install --cask Ubersicht # desktop customization
# brew install --cask xquartz # X11
# https://www.trankynam.com/atext and http://www.phraseexpress.com/ - text expansion. Note: Alfred also does text expansion

brew cleanup

# AppStore apps:
# mas install 937984704 # Amphetamine - keep your Mac awake
mas install 1044484672 # ApolloOne - Photo Video Viewer. RAW files viewer & EXIF editor
# mas install 576421334 # Converto - The Unit Converter
mas install 1473079126 # Cleaner One: Disk Clean
# mas install 442160987 # Flycut (Clipboard manager)
mas install 1295203466 # Microsoft Remote Desktop

# Install these widget apps from the AppStore:
# nothing currently
