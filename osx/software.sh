#!/bin/bash

# Install homebrew
if [ ! -f /usr/local/bin/brew ]; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew update
brew upgrade

# homebrew-cask
brew tap caskroom/cask

# browsers
brew cask install google-chrome
brew cask install firefox
brew cask install opera

# FUSE, requires reboot
# brew cask install osxfuse

# development
brew cask install atom # code/text editor
brew cask install brackets # code/text editor
brew cask install bwana # browser as man pager
brew cask install dash # documentation sets, code snippets, and text expansion
brew cask install gimp # imaging
brew cask install filezilla # file transfer
brew cask install iterm2 # terminal
brew cask install itsycal # calendar
brew cask install kaleidoscope # file/directory diff/merge
brew cask install kdiff3 # file/directory diff/merge
brew cask install key-codes # key codes
brew cask install p4merge # file diff/merge
brew cask install pycharm # Python IDE
brew cask install snippet-edit # XCode snippets
brew cask install sourcetree # Git gui
brew cask install sublime-text # code/text editor
brew cask install uncrustifyx # Source Code Beautifier for C-style languages
brew cask install virtualbox # virtual machines

# other
brew cask install alfred # Spotlight-replacement, workflow automation
brew cask install appcleaner # apps cleaner
brew cask install calibre # books
brew cask install cheatsheet # Hold the Command key longer in any app to get a list of keyboard shortcuts
brew cask install disk-inventory-x # disk utilization
brew cask install dropbox # files sync
brew cask install evernote # notes sync
brew cask install etcher # burn images to USB drives & SD cards
brew cask install flux # color adjustments
brew cask install handbrake # video transcoder
brew cask install hermes # Pandora.com
brew cask install karabiner-elements # keyboard customization
brew cask install keepassxc # passwords sync
brew cask install kindle # books
brew cask install mplayer-osx-extended # media
brew cask install onyx # system maintenance, files cleanup
brew cask install pacifist # OSX package files extractor
brew cask install packet-peeper # network monitor
brew cask install skype # chat
brew cask install slate # window management
brew cask install teamviewer # remote sharing
brew cask install the-unarchiver # unarchive many archive formats
brew cask install transmission # Bittorrent client
brew cask install tunnelblick # OpenVPN client
brew cask install vlc # media player
brew cask install wireshark # network monitor, depends on xquartz
brew cask install xrg # System Monitor for OSX

# Developer-friendly quick-look plugins; see https://github.com/sindresorhus/quick-look-plugins
brew cask install qlcolorcode qlstephen qlmarkdown quicklook-json qlprettypatch quicklook-csv betterzipql qlimagesize webpquicklook suspicious-package

# Remove outdated versions from the cellar.
brew prune
brew cleanup

# AppStore apps:
mas install 576421334 # Converto - The Unit Converter
mas install 921458519 # Dr. Cleaner: Disk, Mem Clean
# mas install 442160987 # Flycut (Clipboard manager)
mas install 715768417 # Microsoft Remote Desktop
mas install 639968404 # Parcel - Delivery Tracking

# Install these widget apps from the AppStore:

# Unused
# brew cask install carbon-copy-cloner # disk copy
# brew cask install ccmenu # CI server status
# brew cask install geektool # OSX desktop customization
# brew cask install gisto # Github gists editor
# brew cask install googleappengine # cloud apps
# brew install homebrew/x11/meld # file/directory diff/merge
# brew cask install loading # shows network activity per app
# brew cask install murus # UI for OSX's Packet Firewall
# brew cask install peakhour # network bandwidth monitoring and reporting
# brew cask install spectacle # window management
# brew cask install superduper # disk duplication
# brew cask install Ubersicht # desktop customization
# brew cask install xquartz # X11
# https://www.trankynam.com/atext and http://www.phraseexpress.com/ - text expansion. Note: Alfred also does text expansion
