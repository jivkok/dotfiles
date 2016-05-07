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
brew cask install brackets # code/text editor
brew cask install filezilla # file transfer
brew cask install dash # documentation sets
brew cask install gimp # imaging
brew cask install gisto # Github gists editor
brew cask install google-chrome # browser
brew cask install googleappengine # cloud apps
brew cask install iterm2 # terminal
brew cask install kaleidoscope # file/directory diff/merge
brew cask install kdiff3 # file/directory diff/merge
brew install homebrew/x11/meld # file/directory diff/merge
brew cask install p4merge # file diff/merge
brew cask install pycharm-ce # Python IDE
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
brew cask install clipmenu # clipboard manager
brew cask install disk-inventory-x # disk utilization
brew cask install dropbox # files sync
brew cask install evernote # notes sync
brew cask install firefox # browser
brew cask install flux # color adjustments
brew cask install hermes # Pandora.com
brew cask install karabiner # keyboard customization (together with seil)
brew cask install keepassx # passwords sync
brew cask install kindle # books
brew cask install loading # shows network activity per app
brew cask install mplayer-osx-extended # media
brew cask install pacifist # OSX package files extractor
brew cask install packet-peeper # network monitor
brew cask install private-eye # network monitor
brew cask install remote-desktop-connection # Windows connectivity
brew cask install seil # keyboard customization (together with karabiner)
brew cask install skype # chat
brew cask install slate # window management
brew cask install spectacle # window management
brew cask install superduper # disk duplication
# brew cask install teamviewer # remote sharing
brew cask install tunnelblick # OpenVPN client
brew cask install vlc # media player
brew cask install wireshark # network monitor, depends on xquartz
brew cask install xquartz # X11

# Remove outdated versions from the cellar.
brew cleanup
