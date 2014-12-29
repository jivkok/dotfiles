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
brew cask install diffmerge
brew cask install filezilla
brew cask install gimp
brew cask install iterm2
brew cask install kaleidoscope
brew cask install kdiff3
brew cask install snippet-edit
brew cask install sourcetree
brew cask install sublime-text3
brew cask install uncrustifyx
brew cask install virtualbox

# other
brew cask install alfred
brew cask install appcleaner
brew cask install calibre
brew cask install cleanmymac
brew cask install disk-inventory-x
brew cask install dropbox
brew cask install evernote
brew cask install keepassx
brew cask install private-eye
brew cask install remote-desktop-connection
brew cask install skype
brew cask install spectacle
brew cask install superduper
# brew cask install teamviewer
brew cask install wireshark

# setup
brew cask alfred link
