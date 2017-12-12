#!/bin/bash
# Brew packages

# Install homebrew
if [ ! -f /usr/local/bin/brew ]; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Ask for the administrator password upfront.
sudo -v
# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

brew tap universal-ctags/universal-ctags
brew tap neovim/neovim

brew update
brew upgrade

# Install GNU core utilities (those that come with OS X are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
rm -f /usr/local/bin/sha256sum && ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum
brew install moreutils
brew install findutils # GNU `find`, `locate`, `updatedb`, and `xargs`
brew install gnu-sed --with-default-names
brew install gnu-tar --with-default-names
brew install gnu-which --with-default-names
brew install gawk
brew install gnutls
brew install wget --with-iri
brew install grep --with-default-names
brew install rsync
brew install php56 --with-gmp

# Install Bash 4.
brew install bash
brew install bash-completion
# Switch to Bash4 with:
# echo /usr/local/bin/bash | sudo tee -a /etc/shells
# chsh -s /usr/local/bin/bash

# Packages
brew install ack
brew install asciinema # Record and share terminal sessions
brew install bfg
brew install binutils
brew install binwalk
brew install ccat
brew install cifer
brew install cmake
brew install dex2jar
brew install dns2tcp
brew install dos2unix
brew install duti
# brew install exiv2
brew install fasd
brew install fcrackzip
brew install ffmpeg
brew install foremost
brew install fzf
[ -f /usr/local/opt/fzf/install ] && /usr/local/opt/fzf/install --key-bindings --completion --no-update-rc
brew install git
brew install git-extras
brew install graphviz
brew install gzip
brew install hashpump
brew install htop-osx
brew install hydra
brew install iftop
brew install imagemagick --with-webp
brew install john
brew install jq
brew install knock
brew install lnav
brew install lsof
brew install lua
brew install lynx
brew install mas
brew install mobile-shell
brew install ngrep
brew install nmap
brew install p7zip
brew install pigz
brew install pngcheck
brew install pt
brew install pv
brew install ranger # libcaca highlight atool lynx w3m elinks poppler transmission mediainfo exiftool
brew install rename
brew install rhino
brew install screenfetch
brew install shellcheck
brew install socat
brew install speedtest_cli
brew install sqlmap
brew install ssh-copy-id
brew install tcpflow
brew install tcpreplay
brew install tcptrace
brew install the_silver_searcher
brew install tmux
brew install tree
brew install ucspi-tcp # `tcpserver` etc.
brew install universal-ctags --HEAD
brew install unix2dos
brew install watch
brew install webkit2png
brew install xpdf
brew install xz
brew install zopfli

# Lxml and Libxslt
brew install libxml2
brew install libxslt
brew link libxml2 --force
brew link libxslt --force

# Vim
brew install vim --override-system-vi --with-lua
brew install macvim --HEAD --with-cscope --with-lua --with-override-system-vim --with-luajit --with-python
brew linkapps macvim
brew install neovim

# TaskWarrior
brew install task
brew install vit

# Reference-only, requires osxfuse
# brew install sshfs # File system client based on SSH File Transfer Protocol

# Remove outdated versions from the cellar.
brew prune
brew cleanup

# m-cli
INSTALL_DIR=$HOME/.m-cli sh <(curl -fsSL https://raw.githubusercontent.com/rgcr/m-cli/master/install.sh)
