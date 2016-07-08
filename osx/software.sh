#!/bin/sh

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

# development
brew cask install atom # code/text editor
brew cask install brackets # code/text editor
brew cask install ccmenu # CI server status
brew cask install dash # documentation sets
brew cask install gimp # imaging
brew cask install gisto # Github gists editor
brew cask install google-chrome # browser
brew cask install googleappengine # cloud apps
brew cask install filezilla # file transfer
brew cask install iterm2 # terminal
brew cask install kaleidoscope # file/directory diff/merge
brew cask install kdiff3 # file/directory diff/merge
brew cask install key-codes # key codes
brew install homebrew/x11/meld # file/directory diff/merge
brew cask install p4merge # file diff/merge
brew cask install pycharm # Python IDE
brew cask install snippet-edit # XCode snippets
brew cask install sourcetree # Git gui
brew cask install sublime-text # code/text editor
brew cask install uncrustifyx # documentation sets
brew cask install virtualbox # virtual machines

# other
brew cask install alfred # Spotlight-replacement, workflow automation
brew cask install appcleaner # apps cleaner
brew cask install calibre # books
brew cask install carbon-copy-cloner # disk copy
brew cask install clipmenu # clipboard manager
brew cask install disk-inventory-x # disk utilization
brew cask install dropbox # files sync
brew cask install evernote # notes sync
brew cask install firefox # browser
brew cask install flux # color adjustments
brew cask install handbrake # video transcoder
brew cask install hermes # Pandora.com
brew cask install karabiner # keyboard customization (together with seil)
brew cask install keepassx # passwords sync
brew cask install kindle # books
brew cask install loading # shows network activity per app
brew cask install mplayer-osx-extended # media
brew cask install murus # UI for OSX's Packet Firewall
brew cask install pacifist # OSX package files extractor
brew cask install packet-peeper # network monitor
brew cask install peakhour # network bandwidth monitoring and reporting
brew cask install private-eye # network monitor
brew cask install seil # keyboard customization (together with karabiner)
brew cask install skype # chat
brew cask install slate # window management
brew cask install spectacle # window management
brew cask install superduper # disk duplication
# brew cask install teamviewer # remote sharing
brew cask install transmission # Bittorrent client
brew cask install tunnelblick # OpenVPN client
brew cask install vlc # media player
brew cask install wireshark # network monitor, depends on xquartz
brew cask install xquartz # X11

# Developer-friendly quick-look plugins; see https://github.com/sindresorhus/quick-look-plugins
brew cask install qlcolorcode qlstephen qlmarkdown quicklook-json qlprettypatch quicklook-csv betterzipql qlimagesize webpquicklook suspicious-package

# Remove outdated versions from the cellar.
brew prune
brew cleanup

echo Install these apps from the AppStore:
echo * Dr. CLeaner
echo * Microsoft Remote Desktop
