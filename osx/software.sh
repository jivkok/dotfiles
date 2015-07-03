#!/bin/sh

# Install homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# homebrew-cask
brew install caskroom/cask/brew-cask
brew tap caskroom/versions

# browsers
brew cask install google-chrome
brew cask install firefox

# development
brew cask install atom # code/text editor
brew cask install filezilla # file transfer
brew cask install dash # documentation sets
brew cask install gimp # imaging
brew cask install gisto # Github gists editor
brew cask install iterm2 # terminal
brew cask install kaleidoscope # file diff
brew cask install kdiff3 # file diff
brew cask install snippet-edit # XCode snippets
brew cask install sourcetree # Git gui
brew cask install sublime-text3 # code/text editor
brew cask install uncrustifyx # documentation sets
brew cask install virtualbox # virtual machines

# other
brew cask install alfred # Spotlight-replacement, workflow automation
brew cask install appcleaner # apps cleaner
brew cask install calibre # books
brew cask install cleanmymac # apps & mac cleaner
brew cask install disk-inventory-x # disk utilization
brew cask install dropbox # files sync
brew cask install evernote # notes sync
brew cask install hermes # Pandora.com
brew cask install keepassx # passwords sync
brew cask install mplayer-osx-extended # media
brew cask install pacifist # OSX package files extractor
brew cask install private-eye # network monitor
brew cask install remote-desktop-connection # Windows connectivity
brew cask install skype # chat
brew cask install spectacle # window management
brew cask install superduper # disk duplication
# brew cask install teamviewer # remote sharing
brew cask install xquartz # X11
brew cask install wireshark # network monitor, depends on xquartz

# Remove outdated versions from the cellar.
brew cleanup
