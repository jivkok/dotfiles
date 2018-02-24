# ls dirs flag
if ls ~ --group-directories-first > /dev/null 2>&1; then
    dirsflag="--group-directories-first"
else
    dirsflag=""
fi
# ls color flag
if ls --color ~ > /dev/null 2>&1; then
    # GNU
    colorflag="--color=auto"
elif ls -G ~ > /dev/null 2>&1; then
    # OSX
    colorflag="-G"
else
    colorflag=""
fi

function cdd () {
    cd "$1" || exit;
    ls -AlF $dirsflag $colorflag;
}
unset dirsflag colorflag

function lsd() {
    local dir=.
    if [ -n "$1" ]; then
        dir="$1"
    fi
    find "$dir" -mindepth 1 -maxdepth 1 -type d
}

function ff() {
    if [ -z "$1" ]; then
        echo "Find Files (or directories)"
        echo "Usage: ff file_pattern [directory]"
        return
    fi

    file_pattern="$1"
    directory="$2"
    if [ -z "$directory" ]; then
        directory='.'
    fi

    find "$directory" -iname "$file_pattern"
}

function fs() {
    if [ -z "$1" ]; then
        echo "Find Strings in files"
        echo "Usage: fs string_pattern [file_pattern] [directory]"
        return
    fi

    string_pattern="$1"
    file_pattern="$2"
    directory="$3"
    if [ -z "$file_pattern" ]; then
        file_pattern='*'
    fi
    if [ -z "$directory" ]; then
        directory='.'
    fi

    # find "$directory" -type f -iname "$file_pattern" -exec grep -I -l -i "$string_pattern" {} \; -exec grep -I -n -i "$string_pattern" {} \;
    # ack
    # ag
    # rg
    grep -Hrn "$string_pattern" "$directory" --include "$file_pattern"
}

# find and list processes matching a case-insensitive partial-match string
function fp() {
    ps Ao pid,comm | awk '{match($0,/[^\/]+$/); print substr($0,RSTART,RLENGTH)": "$1}' | grep -i "$1" | grep -v grep
}

# open file/s in Emacs (in current session, if any) in new frame
function em() {
    if ! pgrep -f -u $USER "emacs --daemon">/dev/null 2>&1; then
        emacs --daemon
    fi

    emacsclient -c "$@"
}

# open file/s in Emacs in existing frame/session
function ems() {
    if ! pgrep -f -u $USER "emacs --daemon">/dev/null 2>&1; then
        emacs --daemon "$@"
        emacsclient "$@"
    else
        emacsclient -n "$@"
    fi
}

# close existing Emacs session
function emq() {
    if pgrep -f -u $USER "emacs --daemon">/dev/null 2>&1; then
        emacsclient -e "(kill-emacs)" "$@"
    fi
}

# system update
function os_update() {
    echo -e "\nUpdating system ...\n"

    # dotfiles
    local dotdir="$HOME/dotfiles"
    if [ -d "$dotdir/.git" ]; then
        echo -e "\nUpdating dotfiles ...\n"
        git -C "$dotdir" pull --prune
        # git -C "$dotdir" pull --prune --recurse-submodules
        # git -C "$dotdir" submodule update --init --recursive
        echo -e "\nUpdating dotfiles done.\n"
    fi

    if command -V brew >/dev/null 2>&1 ; then
        echo -e "\nUpdating Homebrew packages ...\n"
        brew update
        brew upgrade
        brew prune
        brew cleanup
        brew doctor
        cask cleanup
        cask doctor
        echo -e "\nUpdating Homebrew packages done.\n"
    fi

    if command -V apt-get >/dev/null 2>&1 ; then
        echo -e "\nUpdating apt-get packages ...\n"
        sudo apt-get update --fix-missing
        sudo apt-get dist-upgrade
        sudo apt-get clean
        sudo apt-get autoremove
        echo -e "\nUpdating system packages done.\n"
    fi

    [ -f /usr/local/opt/fzf/install ] && /usr/local/opt/fzf/install --key-bindings --completion --no-update-rc

    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo -e "\nUpdating oh-my-zsh ...\n"
        git -C "$HOME/.oh-my-zsh" pull --rebase --stat origin master

        find "$HOME/.oh-my-zsh/custom/plugins" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
            [ -d "$dir/.git" ] && echo -e "\nUpdating $dir \n" && git -C "$dir" pull --prune
        done
        echo -e "\nUpdating oh-my-zsh done.\n"
    fi

    if command -V vim >/dev/null 2>&1 ; then
        echo -e "\nUpdating Vim plugins ...\n"
        vim +PlugUpdate +qall
        echo -e "\nUpdating Vim plugins done.\n"
    fi
    if command -V nvim >/dev/null 2>&1 ; then
        echo -e "\nUpdating NeoVim plugins ...\n"
        nvim +PlugUpdate +qall
        echo -e "\nUpdating NeoVim plugins done.\n"
    fi

    if command -V pip >/dev/null 2>&1 ; then
        # echo -e "\nUpdating Python system packages ...\n"
        # pip list --outdated --format=columns | tail -n +3 | cut -d ' ' -f 1 | xargs -n 1 sudo -H pip install --upgrade
        # echo -e "\nUpdating Python system packages done.\n"
        echo -e "\nUpdating Python user packages ...\n"
        pip list --user --outdated --format=columns | tail -n +3 | cut -d ' ' -f 1 | xargs -n 1 pip install --user --upgrade
        echo -e "\nUpdating Python user packages done.\n"
    fi

    if command -V npm >/dev/null 2>&1 ; then
        echo -e "\nUpdating Node packages ...\n"
        npm install npm@latest -g
        npm update -g
        sudo -E env "PATH=$PATH" n stable
        npm cache verify
        bower cache clean
        echo -e "\nUpdating Node packages done.\n"
    fi

    # if command -V gem >/dev/null 2>&1 ; then
    #     echo -e "\nUpdating Ruby packages ...\n"
    #     gem update --system
    #     gem update
    #     echo -e "\nUpdating Ruby packages done.\n"
    # fi

    echo -e "\nUpdating system done.\n"
}

# lazy man extract - example: ex tarball.tar
function ex() {
    if [ -f "$1" ] ; then
        case $1 in
            *.tar.bz2)   tar xjfv "$1"        ;;
            *.tar.gz)    tar xzfv "$1"     ;;
            *.tar.xz)    tar xJfv "$1"     ;;
            *.bz2)       bunzip2 "$1"       ;;
            *.rar)       rar x "$1"     ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xfv "$1"        ;;
            *.tbz2)      tar xjfv "$1"      ;;
            *.tgz)       tar xzfv "$1"       ;;
            *.zip)       unzip "$1"     ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"    ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# ls for archives (inspired by `extract`)
lsz() {
    if [ $# -ne 1 ]
    then
        echo "lsz filename.[tar,tgz,gz,zip,etc]"
        return 1
    fi
    if [ -f "$1" ] ; then
        case $1 in
            *.tar.bz2|*.tar.gz|*.tar|*.tbz2|*.tgz) tar tvf "$1";;
            *.zip)  unzip -l "$1";;
            *)      echo "'$1' unrecognized." ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Simple calculator
function calc() {
    local result="";
    result="$(echo "scale=10;$*" | bc --mathlib | tr -d '\\\n')";
    #                       └─ default (when `--mathlib` is used) is 20
    #
    if [[ "$result" == *.* ]]; then
        # improve the output for decimal numbers
        echo "$result" |
        sed -e 's/^\./0./'       \ # add "0" for cases like ".5"
            -e 's/^-\./-0./'     \ # add "0" for cases like "-.5"
            -e 's/0*$//;s/\.$//';  # remove trailing zeros
    else
        echo "$result";
    fi;
    printf "\n";
}

# Create a new directory and enter it
function mkd() {
    mkdir -p "$@" && cd "$_" || exit;
}

# Create a .tar.gz archive, using `zopfli`, `pigz` or `gzip` for compression
function targz() {
    local tmpFile="${*%/}.tar";
    tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1;

    size=$(
        stat -f"%z" "${tmpFile}" 2> /dev/null; # OS X `stat`
        stat -c"%s" "${tmpFile}" 2> /dev/null # GNU `stat`
    );

    local cmd="";
    if (( size < 52428800 )) && hash zopfli 2> /dev/null; then
        # the .tar file is smaller than 50 MB and Zopfli is available; use it
        cmd="zopfli";
    else
        if hash pigz 2> /dev/null; then
            cmd="pigz";
        else
            cmd="gzip";
        fi;
    fi;

    echo "Compressing .tar using \`${cmd}\`…";
    "${cmd}" -v "${tmpFile}" || return 1;
    [ -f "${tmpFile}" ] && rm "${tmpFile}";
    echo "${tmpFile}.gz created successfully.";
}

# Create a data URL from a file
function dataurl() {
    local mimeType
    mimeType=$(file -b --mime-type "$1");
    if [[ $mimeType == text/* ]]; then
        mimeType="${mimeType};charset=utf-8";
    fi
    echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')";
}

# Pull all repos in the current (or specified) directory
function git_pull_all() {
    dir="${1:-.}"
    find "$dir" -mindepth 1 -maxdepth 1 -type d | while read -r repodir; do
        [ -d "$repodir/.git" ] && echo -e "\nRepo: $repodir" && git -C "$repodir" pull --prune;
    done
}

function git_pull_submodules() {
    dir="${1:-.}"

    if [ ! -f "$dir/.gitmodules" ]; then
        echo "No submodules found."
        return
    fi

    sed -rn 's/\s+path\ =\ (.*)/\1/p' "$dir/.gitmodules" | while read -r repodir
    do
        echo -e "\n\033[0;32mUpdating $repodir ...\033[0;39m\n"
        git -C "$repodir" checkout master
        git -C "$repodir" pull --prune --recurse-submodules
        git -C "$repodir" submodule update --init --recursive
    done
}

# Create a git.io short URL
function gitio() {
    if [ -z "${1}" ] || [ -z "${2}" ]; then
        echo "Usage: \`gitio slug url\`";
        return 1;
    fi;
    curl -i http://git.io/ -F "url=${2}" -F "code=${1}";
}

# Start an HTTP server from a directory, optionally specifying the port
function server() {
    local port="${1:-8000}";
    sleep 1 && open "http://localhost:${port}/" &
    # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
    # And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
    python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port";
}

# Start a PHP server from a directory, optionally specifying the port
# (Requires PHP 5.4.0+.)
function phpserver() {
    local interface ip port
    interface=$1
    if [ -z "$interface" ]; then interface=en0; fi
    ip=$(ipconfig getifaddr $interface);
    port="${2:-4000}";
    echo "Interface: $interface; ip: $ip; port: $port"
    sleep 1 && open "http://${ip}:${port}/" &
    php -S "${ip}:${port}";
}

# Syntax-highlight JSON strings or files
# Usage: `json '{"foo":42}'` or `echo '{"foo":42}' | json`
function json() {
    if [ -t 0 ]; then # argument
        python -mjson.tool <<< "$*" | pygmentize -l javascript;
    else # pipe
        python -mjson.tool | pygmentize -l javascript;
    fi;
}

# UTF-8-encode a string of Unicode symbols
function escape() {
    printf "\\\x%s" $(printf "%s" "$@" | xxd -p -c1 -u);
    # print a newline unless we’re piping the output to another program
    if [ -t 1 ]; then
        echo ""; # newline
    fi;
}

# Decode \x{ABCD}-style Unicode escape sequences
function unidecode() {
    perl -e "binmode(STDOUT, ':utf8'); print \"$*\"";
    # print a newline unless we’re piping the output to another program
    if [ -t 1 ]; then
        echo ""; # newline
    fi;
}

# encode a given image file as base64 and output css background property to clipboard
function img2base64() {
    openssl base64 -in "$1" | awk -v ext="${1#*.}" '{ str1=str1 $0 }END{ print "background:url(data:image/"ext";base64,"str1");" }' | pbcopy
    echo "$1 encoded as base64 and copied as css background property to clipboard"
}

# encode a given font file as base64 and output css src property to clipboard
function 64font() {
    openssl base64 -in "$1" | awk -v ext="${1#*.}" '{ str1=str1 $0 }END{ print "src:url(\"data:font/"ext";base64,"str1"\")  format(\"woff\");" }' | pbcopy
    echo "$1 encoded as font and copied as css src property to clipboard"
}

# Get a character’s Unicode code point
function codepoint() {
    perl -e "use utf8; print sprintf('U+%04X', ord(\"$*\"))";
    # print a newline unless we’re piping the output to another program
    if [ -t 1 ]; then
        echo ""; # newline
    fi;
}

# Show all the names (CNs and SANs) listed in the SSL certificate
# for a given domain
function getcertnames() {
    if [ -z "${1}" ]; then
        echo "ERROR: No domain specified.";
        return 1;
    fi;

    local domain="${1}";
    echo "Testing ${domain}…";
    echo ""; # newline

    local tmp
    tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
        | openssl s_client -connect "${domain}:443" -servername "${domain}" 2>&1);

    if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
        local certText
        certText=$(echo "${tmp}" \
            | openssl x509 -text -certopt "no_aux, no_header, no_issuer, no_pubkey, \
            no_serial, no_sigdump, no_signame, no_validity, no_version");
        echo "Common Name:";
        echo ""; # newline
        echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//" | sed -e "s/\/emailAddress=.*//";
        echo ""; # newline
        echo "Subject Alternative Name(s):";
        echo ""; # newline
        echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
            | sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2;
        return 0;
    else
        echo "ERROR: Certificate not found.";
        return 1;
    fi;
}

# MAC lookup
function mac-lookup() {
    local mac="$1"
    if [ -z "$mac" ]; then
        echo "MAC vendor lookup"
        echo "Usage: mac-lookup MAC_address_or_prefix"
        return
    fi

    mac=${mac//:/}
    mac=${mac:0:6}

    curl "https://api.macvendors.com/$mac"
}

# `tre` is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
function tre() {
    tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX;
}

# colorized man
function man() {
    env \
        LESS_TERMCAP_md=$'\e[1;36m' \
        LESS_TERMCAP_me=$'\e[0m' \
        LESS_TERMCAP_se=$'\e[0m' \
        LESS_TERMCAP_so=$'\e[1;40;92m' \
        LESS_TERMCAP_ue=$'\e[0m' \
        LESS_TERMCAP_us=$'\e[1;32m' \
        man "$@"
}

# Helps identifying the source/content of a command
function help() {
    local cmd="$1"
    if [ -z "$cmd" ]; then
        echo "Helps identifying the source/content of a command"
        echo "Usage: help command"
        return
    fi

    local DEFAULT="\033[0;39m" RED="\033[0;31m" GREEN="\033[0;32m"
    local hasPygmentize=0
    command -V pygmentize >/dev/null 2>&1 && hasPygmentize=1

    local cmdtest
    cmdtest="$(type "$cmd")" # command -V, which

    # alias
    if [[ $cmdtest == *"is an alias for"* ]]; then
        echo -e "${GREEN}Alias${DEFAULT}"
        if [[ $hasPygmentize == 1 ]]; then
            alias "$cmd" | pygmentize -l sh
        else
            alias "$cmd"
        fi
        return
    fi

    # function
    if [[ $cmdtest == *"is a shell function"* ]]; then
        echo -e "${GREEN}${cmdtest}${DEFAULT}"
        if [[ $hasPygmentize == 1 ]]; then
            which "$cmd" | pygmentize -l sh
        else
            which "$cmd"
        fi
        return
    fi

    # file
    local f
    f="$(echo "$cmdtest" | sed -r 's/.+\ is\ (.*)/\1/')"
    if [ -f "$f" ]; then
        echo -e "${GREEN}${cmdtest}${DEFAULT}"
        file "$f"
        return
    fi

    # man

    if man "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}Found man entry for: ${cmd}${DEFAULT}"
        man "$cmd"
        return
    fi

    # whatis
    local mantest
    mantest="$(man -f "$cmd")"
    if [[ $mantest != *"nothing appropriate"* ]]; then
        echo -e "${GREEN}Found whatis entries for: ${cmd}${DEFAULT}"
        man -f "$cmd"
        return
    fi

    # apropos
    mantest="$(man -k "$cmd")"
    if [[ $mantest != *"nothing appropriate"* ]]; then
        echo -e "${GREEN}Found whatis strings for: ${cmd}${DEFAULT}"
        man -k "$cmd"
        return
    fi

    echo -e "${RED}Could not find anything for: ${cmd}${DEFAULT}"
    return 1
}

function psgrep () {
    if [ -z "$1" ]; then
        ps aux
    else
        ps aux | grep -iE "$1"
    fi
}

# Tails the system log
function sys_log () {
    local os
    os="$(uname -s)"
    if [ "$os" = "Linux" ]; then
        syslog=/var/log/syslog
    elif [ "$os" = "Darwin" ]; then
        syslog=/var/log/system.log
    else
        echo "Unsupported OS: $os"
        return
    fi

    if [[ $# -gt 0 ]]; then
        query=$(echo "$*"|tr -s ' ' '|')
        tail -f $syslog|grep -i --color=auto -E "$query"
    else
        tail -f $syslog
    fi
}

shell () {
  ps | grep "$$" | awk '{ print $4 }'
}

#######################################
# Disk usage
# Arguments:
#   $1 - directory
#   $2 - depth
# Returns:
#   List of directories and their cummulative size
usage() {
  local _dushow _dusort
  if echo zzz | sort -h > /dev/null 2>&1; then
    _dushow="-h"
    _dusort="-h"
  else
    _dushow=""
    _dusort="-n"
  fi

  du $_dushow --max-depth="${2:-1}" "${1:-.}" | sort $_dusort -r | sed "s:\./::" | sed "s:$HOME:~:"
}

# Git FZF functions ###########################################################

# checkout git branch (including remote branches)
git-fzf-checkout-branch() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" | fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout "$(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")"
}

# checkout git tag
git-fzf-checkout-tag() {
  local branches branch
  tags=$(git tag) &&
  tag=$(echo "$tags" | fzf-tmux -d $(( 2 + $(wc -l <<< "$tags") )) +m) &&
  git checkout "$tag"
}

# checkout git branch/tag
git-fzf-checkout-branch-or-tag() {
  local tags branches target
  tags=$(
    git tag | awk '{print "\x1b[31;1mtag\x1b[m\t" $1}') || return
  branches=$(
    git branch --all | grep -v HEAD             |
    sed "s/.* //"    | sed "s#remotes/[^/]*/##" |
    sort -u          | awk '{print "\x1b[34;1mbranch\x1b[m\t" $1}') || return
  target=$(
    (echo "$tags"; echo "$branches") |
    fzf-tmux -l30 -- --no-hscroll --ansi +m -d "\t" -n 2) || return
  git checkout "$(echo "$target" | awk '{print $2}')"
}

# checkout git commit
git-fzf-checkout-commit() {
  local commits commit
  commits=$(git log --pretty=oneline --abbrev-commit --reverse) &&
  commit=$(echo "$commits" | fzf --tac +s +m -e) &&
  git checkout "$(echo "$commit//" | sed "s/ .*//")"
}

# git commits browser
git-fzf-commits() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

# git commit sha browser
# example usage: git rebase -i $(git-fzf-sha)
git-fzf-sha() {
  local commits commit
  commits=$(git log --color=always --pretty=oneline --abbrev-commit --reverse) &&
  commit=$(echo "$commits" | fzf --tac +s +m -e --ansi --reverse) &&
  echo -n $(echo "$commit" | sed "s/ .*//")
}

# git stash manager
# enter key: shows stash contents
# ctrl-d: shows a diff of the stash against current HEAD
# ctrl-b: checks out the stash as a branch
git-fzf-stashes() {
  local out q k sha
  while out=$(
    git stash list --pretty="%C(yellow)%h %>(14)%Cgreen%cr %C(blue)%gs" |
    fzf --ansi --no-sort --query="$q" --print-query \
        --expect=ctrl-d,ctrl-b);
  do
    mapfile -t out <<< "$out"
    q="${out[0]}"
    k="${out[1]}"
    sha="${out[-1]}"
    sha="${sha%% *}"
    [[ -z "$sha" ]] && continue
    if [[ "$k" == 'ctrl-d' ]]; then
      git diff "$sha"
    elif [[ "$k" == 'ctrl-b' ]]; then
      git stash branch "stash-$sha" "$sha"
      break;
    else
      git stash show -p "$sha"
    fi
  done
}

gitf() {
    if [ "$1" = "co" ] || [ "$1" = "checkout" ]; then
        if [ "$2" = "br" ] || [ "$1" = "branch" ]; then
            git-fzf-checkout-branch
        elif [ "$2" = "tag" ]; then
            git-fzf-checkout-tag
        elif [ "$2" = "cm" ] || [ "$1" = "commit" ]; then
            git-fzf-checkout-commit
        else
            echo "Usage: gitf checkout branch/tag/commit"
        fi
    elif [ "$1" = "commits" ]; then
        git-fzf-commits
    elif [ "$1" = "sha" ]; then
        git-fzf-sha
    elif [ "$1" = "stashes" ]; then
        git-fzf-stashes
    else
        echo "Usage: gitf checkout/commits/sha/stashes"
    fi
}

# OS-specific functions ######################################################

os=$(uname -s)

if [ "$os" = "Darwin" ]; then
    # `o` with no arguments opens the current directory, otherwise opens the given location
    function o() {
        if [ $# -eq 0 ]; then
            open .;
        else
            open "$@";
        fi;
    }

    # cd to the path of the front Finder window
    cdf() {
        target=$(osascript -e 'tell application "Finder" to if (count of Finder windows) > 0 then get POSIX path of (target of front Finder window as text)')
        if [ "$target" != "" ]; then
            cd "$target" || exit; pwd
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
            height=$(sips -g pixelHeight "$1"|tail -n 1|awk '{print $2}')
            width=$(sips -g pixelWidth "$1"|tail -n 1|awk '{print $2}')
            echo "${width} x ${height}"
        else
            echo "File not found"
        fi
    }
fi
