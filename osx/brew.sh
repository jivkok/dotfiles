#!/bin/sh

# Install homebrew
if [ ! -f /usr/local/bin/brew ]; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Ask for the administrator password upfront.
sudo -v
# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Install GNU core utilities (those that come with OS X are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
sudo ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum

brew install moreutils
brew install findutils # GNU `find`, `locate`, `updatedb`, and `xargs`
brew install gnu-sed --with-default-names
brew install gnu-tar --with-default-names
brew install gnu-which --with-default-names
# Install Bash 4.
# Note: don’t forget to add `/usr/local/bin/bash` to `/etc/shells` before running `chsh`.
brew install bash
brew install bash-completion

# Install `wget` with IRI support.
brew install wget --with-iri

# Install more recent versions of some OS X tools.
brew install vim --override-system-vi
brew install homebrew/dupes/grep
brew install homebrew/php/php55 --with-gmp

# Install some CTF tools; see https://github.com/ctfs/write-ups.
brew install bfg
brew install binutils
brew install binwalk
brew install cifer
brew install cmake
brew install ctags
brew install dex2jar
brew install dns2tcp
brew install fcrackzip
brew install foremost
brew install gzip
brew install hashpump
brew install hydra
brew install john
brew install jq
brew install knock
brew install ngrep
brew install nmap
brew install pngcheck
brew install socat
brew install sqlmap
brew install tcpflow
brew install tcpreplay
brew install tcptrace
brew install the_silver_searcher
brew install tmux
brew install ucspi-tcp # `tcpserver` etc.
brew install watch
brew install xpdf
brew install xz

# Install other useful binaries.
brew install ack
#brew install exiv2
brew install git
brew install git-extras
brew install fzf
[ -f /usr/local/opt/fzf/install ] && /usr/local/opt/fzf/install --key-bindings --completion --no-update-rc
brew install imagemagick --with-webp
brew install lua
brew install lynx
brew install p7zip
brew install pigz
brew install pt
brew install pv
brew install rename
brew install rhino
brew install speedtest_cli
brew install tree
brew install webkit2png
brew install zopfli
brew install duti

# Security-related
brew install htop
brew install iftop
brew install lsof

# Install MacVim
brew install macvim --with-cscope --with-luajit
brew linkapps macvim

# Install Node.js. Note: this installs `npm` too, using the recommended installation method.
brew install node
npm install -g grunt-cli
npm install -g http-server
npm install -g express
npm install -g express-generator
npm install -g yo
npm install -g generator-angular
npm install -g bower
npm install -g nodemon
npm cache clean

# Remove outdated versions from the cellar.
brew cleanup
