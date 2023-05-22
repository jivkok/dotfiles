# Larger bash history (allow 32³ entries; default is 500)
export HISTSIZE=32768
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignoreboth
# Make some commands not show up in history
export HISTIGNORE="..:...:....:* --help:cd:cd -:clear:date:exit:ll:ls:pwd:reload:rr:v:x"

# Prefer US English and use UTF-8
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Highlight section titles in manual pages
export LESS_TERMCAP_md="${yellow}"

# .Net
[ -d "$HOME/.dotnet" ] && export DOTNET_ROOT="$HOME/.dotnet"

# Easier navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Directories
alias md='mkdir'
alias rd='rm -rf'
alias paths='echo -e ${PATH//:/\\n}'

# Misc
alias envs='printenv | sort'
alias h='history'
alias j='jobs'
alias mk='make'
alias nh='unset HISTFILE'
alias rr='ranger'
alias vars='set | sort'
alias vg='vagrant'
alias x='exit'

# System info
## top processes by CPU
alias pscpu10='ps aux | head -1; ps aux | tail -n +2 | sort -nr -k 3 | head -10'
# alias pscpu10='ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10'
## top processes by memory
alias psmem10='ps aux | head -1; ps aux | tail -n +2 | sort -nr -k 4 | head -10'

# memory
alias meminfo='free -m -l -t'

# Networking
alias ports='netstat -tulan'

# Get week number
alias week='date +%V'

# IP addresses
alias ip='dig +short myip.opendns.com @resolver1.opendns.com'
alias localip="ifconfig | grep -Eo 'inet (addr:)?([0-9]+\.){3}[0-9]+' | grep -Eo '([0-9]+\.){3}[0-9]+' | grep -v '127.0.0.1'"

# Reload the shell (i.e. invoke as a login shell)
alias reload='exec $SHELL -l'

# Tmux auto-attach
command -v tmux >/dev/null && alias t='(tmux has-session 2>/dev/null && tmux attach) || (tmux new-session)'

# Helpers

function dot_trace() {
  local msg="$1"
  local timestamp="$(date "+%Y-%m-%d %H:%M:%S")"
  echo -e "\n$(tput setaf 2)$timestamp: $msg$(tput sgr0)\n"
  touch ~/.dotfiles_history
  echo "$timestamp: [INFO] $msg" >>~/.dotfiles_history
}

# system update
function update_os() {
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

  # Package manager updates
  os=$(uname -s)

  if [ "$os" = "Darwin" ] && command -V brew >/dev/null 2>&1; then
    echo -e "\nUpdating Homebrew packages ...\n"
    brew update-reset
    brew upgrade
    brew cleanup
    brew doctor --verbose
    echo -e "\nUpdating Homebrew packages done.\n"
  fi

  if [ "$os" = "Linux" ] && command -V apt-get >/dev/null 2>&1; then
    echo -e "\nUpdating apt-get packages ...\n"
    sudo apt-get update -y --fix-missing
    sudo apt-get dist-upgrade
    sudo apt-get clean
    sudo apt-get autoremove
    echo -e "\nUpdating apt-get packages done.\n"
  fi

  if [ "$os" = "Linux" ] && command -V pacman >/dev/null 2>&1; then
    echo -e "\nUpdating pacman packages ...\n"
    sudo pacman -Syu --needed --noconfirm archlinux-keyring
    sudo pacman -Syyu --overwrite "*"
    echo -e "\nUpdating pacman packages done.\n"
    if command -V yay >/dev/null 2>&1; then
      echo -e "\nUpdating yay packages ...\n"
      yay -Syu --answerupgrade None --answerclean None --answerdiff None
      echo -e "\nUpdating yay packages done.\n"
    fi
  fi

  fzfrepo="$HOME/.repos/fzf"
  if [ -d "$fzfrepo/.git" ]; then
    echo -e "\nUpdating FZF ...\n"
    git -C "$fzfrepo" pull --prune
    "$fzfrepo/install" --key-bindings --completion --no-update-rc

    # fzf-git
    filename="fzf-git.sh"
    url="https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh"
    echo "Downloading $url"
    curl -s -o "$HOME/bin/$filename" "$url"
    chmod 755 "$HOME/bin/$filename"
    echo -e "\nUpdating FZF done.\n"
  fi

  zpluginsdir="$HOME/.zsh/plugins"
  if [ -d "$zpluginsdir" ]; then
    echo -e "\nUpdating ZSH plugins ...\n"
    find "$zpluginsdir" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
      [ -d "$dir/.git" ] && echo -e "\nUpdating $dir \n" && git -C "$dir" pull --prune
    done
    echo -e "\nUpdating ZSH plugins done.\n"
  fi

  if [ -d "$HOME/.tmux/plugins/tpm/bin/update_plugins" ]; then
    echo -e "\nUpdating Tmux plugins ...\n"
    "$HOME/.tmux/plugins/tpm/bin/update_plugins" all
    echo -e "\nUpdating Tmux plugins done.\n"
  fi

  if command -V vim >/dev/null 2>&1; then
    echo -e "\nUpdating Vim plugins ...\n"
    vim +PlugUpdate +qall
    echo -e "\nUpdating Vim plugins done.\n"
  fi
  if command -V nvim >/dev/null 2>&1; then
    echo -e "\nUpdating NeoVim plugins ...\n"
    nvim +PlugUpdate +qall
    echo -e "\nUpdating NeoVim plugins done.\n"
  fi

  if command -V python3 >/dev/null 2>&1; then
    pipcmd="pip3"
  elif command -V python >/dev/null 2>&1; then
    pipcmd="pip"
  fi
  if [ -n "$pipcmd" ]; then
    echo -e "\nUpdating Python user packages ...\n"
    "$pipcmd" list --user --outdated --format=columns | tail -n +3 | cut -d ' ' -f 1 | xargs -n 1 "$pipcmd" install --user --upgrade
    echo -e "\nUpdating Python user packages done.\n"
    echo -e "\nUpdating Python packages ...\n"
    diff <("$pipcmd" list --user --outdated --format=columns | tail -n +3 | cut -d ' ' -f 1) <("$pipcmd" list --outdated --format=columns | tail -n +3 | cut -d ' ' -f 1) | grep '> ' | cut -d ' ' -f 2 | xargs -n 1 sudo -H "$pipcmd" install --upgrade
    echo -e "\nUpdating Python packages done.\n"
  fi

  if command -V npm >/dev/null 2>&1; then
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
  f="$(echo "$cmdtest" | sed -E 's/.+\ is\ (.*)/\1/')"
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

# Create a new directory and enter it
function mkd() {
  mkdir -p "$@" && cd "$_" || exit
}

# `tre` is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
function tre() {
  tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX
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

function history-top-commands() {
  history | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl | head -n20
}

# Tails the system log
function sys_log() {
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
    query=$(echo "$*" | tr -s ' ' '|')
    tail -f $syslog | grep -i --color=auto -E "$query"
  else
    tail -f $syslog
  fi
}

#######################################
# Disk usage
# Arguments:
#   $1 - directory (default: current)
#   $2 - count (default: 20)
#   $3 - depth (default: 1)
# Returns:
#   List of directories and their cummulative size
diskusage() {
  local _dushow _dusort
  if echo zzz | sort -h >/dev/null 2>&1; then
    _dushow="-h"
    _dusort="-h"
  else
    _dushow=""
    _dusort="-n"
  fi

  du $_dushow -d "${3:-1}" -t 1K "${1:-.}" | sort $_dusort -r | head -n "${2:-20}"
}
