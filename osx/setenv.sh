# Get OS X Software Updates, and update installed Ruby gems, Homebrew, npm, and their installed packages
alias update_osx='sudo softwareupdate --install --all --verbose; command -v update_os >/dev/null 2>&1 && update_os'

# Flush Directory Service cache
alias flush='dscacheutil -flushcache && killall -HUP mDNSResponder'

# Clean up LaunchServices to remove duplicates in the “Open With” menu
alias lscleanup='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder'

# OS X has no `md5sum`, so use `md5` as a fallback
command -v md5sum >/dev/null || alias md5sum='md5'

# OS X has no `sha1sum`, so use `shasum` as a fallback
command -v sha1sum >/dev/null || alias sha1sum='shasum'

# JavaScriptCore REPL
jscbin='/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc'
[ -e "${jscbin}" ] && alias jsc="${jscbin}"
unset jscbin

# Recursively delete `.DS_Store` files
alias cleanDS="find . -type f -name '*.DS_Store' -ls -delete"

# Empty the Trash on all mounted volumes and the main HDD
# Also, clear Apple’s System Logs to improve shell startup speed
alias emptytrash='sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl'

# Show/hide hidden files in Finder
alias show='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
alias hide='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'

# Hide/show all desktop icons (useful when presenting)
alias hidedesktop='defaults write com.apple.finder CreateDesktop -bool false && killall Finder'
alias showdesktop='defaults write com.apple.finder CreateDesktop -bool true && killall Finder'

# Merge PDF files
# Usage: `mergepdf -o output.pdf input{1,2,3}.pdf`
alias mergepdf='/System/Library/Automator/Combine\ PDF\ Pages.action/Contents/Resources/join.py'

# Disable Spotlight
alias spotoff='sudo mdutil -a -i off'
# Enable Spotlight
alias spoton='sudo mdutil -a -i on'

# PlistBuddy alias, because sometimes `defaults` just doesn’t cut it
alias plistbuddy='/usr/libexec/PlistBuddy'

# Ring the terminal bell, and put a badge on Terminal.app’s Dock icon
# (useful when executing time-consuming commands)
alias badge='tput bel'

# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"

# Lock the screen (when going AFK)
alias afk='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'

alias of='open -a Finder ./'
alias ql='qlmanage -p &>/dev/null'

if [ -f '/Applications/p4merge.app/Contents/Resources/launchp4merge' ]; then
  alias p4diff='/Applications/p4merge.app/Contents/Resources/launchp4merge $*'
fi

if [ -f "$HOME/.m-cli/m" ]; then
  alias m="$HOME/.m-cli/m $*"
fi

# `o` with no arguments opens the current directory, otherwise opens the given location
function o() {
  if [ $# -eq 0 ]; then
    open .
  else
    open "$@"
  fi
}

# cd to the path of the front Finder window
cdf() {
  target=$(osascript -e 'tell application "Finder" to if (count of Finder windows) > 0 then get POSIX path of (target of front Finder window as text)')
  if [ "$target" != "" ]; then
    cd "$target" || exit
    pwd
  else
    echo 'No Finder window found' >&2
  fi
}

# Query argument in Dash
function dash() {
  open "dash://$*"
}

# Open manpages in Dash
function dman() {
  open "dash://manpages:$*"
}

# Open manpages in browser
function bman() {
  open "man:$*"
}

# Quickly get image dimensions from the command line
function imgsize() {
  local width height
  if [[ -f $1 ]]; then
    height=$(sips -g pixelHeight "$1" | tail -n 1 | awk '{print $2}')
    width=$(sips -g pixelWidth "$1" | tail -n 1 | awk '{print $2}')
    echo "${width} x ${height}"
  else
    echo "File not found"
  fi
}
