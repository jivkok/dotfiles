# Easier navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# Directories
alias md='mkdir'
alias rd='rm -rf'
alias tree2='tree -A -C -L 2 --dirsfirst'
alias tree2a='tree -a -A -C -L 2 --dirsfirst'
alias paths='echo -e ${PATH//:/\\n}'

# Shortcuts
alias ccat='colorize_via_pygmentize'
alias e='subl'
alias envs='printenv | sort'
alias g='git'
alias h='history'
alias j='jobs'
alias lg='lazygit'
alias mk='make'
alias nh='unset HISTFILE'
alias rr='ranger'
alias vars='set | sort'
if command -v nvim >/dev/null 2>&1; then
    alias v='nvim'
elif command -v gvim >/dev/null 2>&1; then
    alias v='gvim'
elif command -v vim >/dev/null 2>&1; then
    alias v='vim'
else
    alias v='vi'
fi
alias vg='vagrant'
alias vimupd='v +PlugUpdate +qall'
alias x='exit'

# Listings
alias l='ls -AF --color=auto --group-directories-first'
alias ll='ls -AlFh --color=auto --group-directories-first'
unset _dirsflag _colorflag
alias recent='ls -alt | head' # Most recent files

# Clipboard
# copy output of last command to clipboard
alias cl='fc -e -|pbcopy'
# copy the working directory path
alias cpwd='pwd|tr -d "\n"|pbcopy'
# show the current cliboard content
alias cbp='pbpaste|less'

# System info
## top processes by CPU
alias pscpu10='ps aux | head -1; ps aux | tail -n +2 | sort -nr -k 3 | head -10'
# alias pscpu10='ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10'
## top processes by memory
alias psmem10='ps aux | head -1; ps aux | tail -n +2 | sort -nr -k 4 | head -10'

# Networking
alias ports='netstat -tulan'

# Get week number
alias week='date +%V'

# Stopwatch
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'

# IP addresses
alias ip='dig +short myip.opendns.com @resolver1.opendns.com'
alias localip="ifconfig | grep -Eo 'inet (addr:)?([0-9]+\.){3}[0-9]+' | grep -Eo '([0-9]+\.){3}[0-9]+' | grep -v '127.0.0.1'"

# URL-encode strings
alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'

# Reload the shell (i.e. invoke as a login shell)
alias reload='exec $SHELL -l'

# Make Grunt print stack traces by default
command -v grunt > /dev/null && alias grunt='grunt --stack'

# Tmux auto-attach
command -v tmux > /dev/null && alias t='(tmux has-session 2>/dev/null && tmux attach) || (tmux new-session)'

# Web servers
alias nginxreload='/usr/local/nginx/sbin/nginx -s reload'
alias nginxtest='/usr/local/nginx/sbin/nginx -t'
alias lightyload='/etc/init.d/lighttpd reload'
alias lightytest='/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf -t'
alias httpdreload='/usr/sbin/apachectl -k graceful'
alias httpdtest='/usr/sbin/apachectl -t && /usr/sbin/apachectl -t -D DUMP_VHOSTS'

# Docker
alias datt='docker attach'
alias ddiff='docker diff'
alias dimg='docker images'
alias dins='docker inspect'
alias dps='docker ps'
alias drm='docker rm'
alias drmi='docker rmi'
alias drun='docker run'
alias dstart='docker start'
alias dstop='docker stop'
alias deb='dexbash'
alias dceb='dcexbash'
alias dc='docker-compose'
alias dcb='docker-compose build'
alias dclogs='docker-compose logs'
alias dcup='docker-compose up'
alias dcdown='docker-compose down'
alias dcstart='docker-compose start'
alias dcstop='docker-compose stop'

# Misc
os=$(uname -s)

if [ "$os" = "Linux" ] || [ "$os" = "Darwin" ]; then

    for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
        alias "$method"="lwp-request -m '$method'"
    done

    # View HTTP traffic
    _interface=eth0
    if [ "$os" = "Darwin" ]; then
        _interface=en1
    fi
    alias sniff="sudo ngrep -d $_interface -t '^(GET|POST) ' 'tcp and port 80'"
    alias httpdump="sudo tcpdump -i $_interface -n -s 0 -w -"
    unset _interface

fi

if [ "$os" = "Linux" ]; then

    # Packages
    alias pkgsearch='apt-cache search'
    alias pkginstall='sudo apt-get install -y'
    alias pkgremove='sudo apt-get remove'
    alias pkglist='apt-cache pkgnames'
    alias pkgshow='apt-cache show'
    alias pkgupdate='sudo apt-get update --fix-missing && sudo apt-get dist-upgrade && sudo apt-get clean && sudo apt-get autoremove'

    # memory
    alias meminfo='free -m -l -t'

elif [ "$os" = "Darwin" ]; then

    if command -v gls >/dev/null 2>&1; then
        alias l='gls -AF --color=auto --group-directories-first'
        alias ll='gls -AlFh --color=auto --group-directories-first'
    else
        alias l='ls -AF -G'
        alias ll='ls -AlFh -G'
    fi

    # Packages
    alias pkgsearch='brew search'
    alias pkginstall='brew install'
    alias pkgremove='brew uninstall'
    alias pkglist='brew list'
    alias pkgshow='brew info'
    alias pkgupdate='brew update && brew upgrade --all && brew cleanup && brew doctor'
    alias cask='brew cask'

    # Get OS X Software Updates, and update installed Ruby gems, Homebrew, npm, and their installed packages
    alias update_osx='sudo softwareupdate --install --all --verbose; command -v update_os >/dev/null 2>&1 && update_os'

    # Flush Directory Service cache
    alias flush='dscacheutil -flushcache && killall -HUP mDNSResponder'

    # Clean up LaunchServices to remove duplicates in the “Open With” menu
    alias lscleanup='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder'

    # OS X has no `md5sum`, so use `md5` as a fallback
    command -v md5sum > /dev/null || alias md5sum='md5'

    # OS X has no `sha1sum`, so use `shasum` as a fallback
    command -v sha1sum > /dev/null || alias sha1sum='shasum'

    # JavaScriptCore REPL
    jscbin='/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc';
    [ -e "${jscbin}" ] && alias jsc="${jscbin}";
    unset jscbin;

    # Recursively delete `.DS_Store` files
    alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"

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
fi
