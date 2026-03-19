# shellcheck shell=bash

# Larger bash history (allow 32³ entries; default is 500)
export HISTSIZE=32768
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignoreboth
# Make some commands not show up in history
export HISTIGNORE="..:...:....:* --help:cd:cd -:clear:date:exit:ll:ls:pwd:reload:rr:x"

# Prefer US English and use UTF-8
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# .Net
[ -d "$HOME/.dotnet" ] && export DOTNET_ROOT="$HOME/.dotnet"

# Go
if [ -d "$HOME/go" ]; then
  export GOPATH="$HOME/go"
  export GOBIN="$GOPATH/bin"
fi

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
# Reload the shell as a login shell
reload() { exec "$SHELL" -l; }

# Filesystem
alias md='mkdir -p'
alias rd='rm -rf'
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

# Shell session
alias h='history'
alias j='jobs'
alias x='exit'
alias nh='unset HISTFILE'

# Tools
alias mk='make'
alias rr='ranger'
# Tmux auto-attach
command -v tmux >/dev/null && alias t='(tmux has-session 2>/dev/null && tmux attach) || (tmux new-session)'

# Environment inspection
alias envs='env | sort'
alias vars='set | sort'
# Print each PATH entry on its own line
paths() { tr ':' '\n' <<< "$PATH"; }

# Misc
alias week='date +%V'

# Override man to display colorized output
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

# Log a timestamped message to the console and ~/.dotfiles_history
function dot_trace() {
  local msg="$1"
  local timestamp
  timestamp="$(date "+%Y-%m-%d %H:%M:%S")"
  if [ -t 1 ]; then
    echo -e "\n$(tput setaf 2)$timestamp: $msg$(tput sgr0)\n"
  else
    echo -e "\n$timestamp: $msg\n"
  fi
  touch ~/.dotfiles_history
  echo "$timestamp: [INFO] $msg" >>~/.dotfiles_history
}

# Update the OS, package managers, shell plugins, and editors
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
  if $_is_osx && command -v brew >/dev/null 2>&1; then
    echo -e "\nUpdating Homebrew packages ...\n"
    brew update
    brew upgrade
    brew cleanup
    brew doctor --verbose
    echo -e "\nUpdating Homebrew packages done.\n"
  fi

  if $_is_linux && command -v apt-get >/dev/null 2>&1; then
    echo -e "\nUpdating apt-get packages ...\n"
    sudo apt-get update -y -qq --fix-missing
    sudo apt-get dist-upgrade
    sudo apt-get clean
    sudo apt-get autoremove
    echo -e "\nUpdating apt-get packages done.\n"
  fi

  if $_is_linux && command -v pacman >/dev/null 2>&1; then
    echo -e "\nUpdating pacman packages ...\n"
    sudo pacman -Syu --needed --noconfirm archlinux-keyring
    sudo pacman -Syyu --overwrite "*"
    echo -e "\nUpdating pacman packages done.\n"
    if command -v yay >/dev/null 2>&1; then
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
    local filename="fzf-git.sh"
    local url="https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh"
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

  if command -v vim >/dev/null 2>&1; then
    echo -e "\nUpdating Vim plugins ...\n"
    vim +PlugUpdate +qall
    echo -e "\nUpdating Vim plugins done.\n"
  fi
  if command -v nvim >/dev/null 2>&1; then
    echo -e "\nUpdating NeoVim plugins ...\n"
    nvim +PlugUpdate +qall
    echo -e "\nUpdating NeoVim plugins done.\n"
  fi

  local pipcmd=""
  if command -v python3 >/dev/null 2>&1; then
    pipcmd="pip3"
  elif command -v python >/dev/null 2>&1; then
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

  if command -v npm >/dev/null 2>&1; then
    echo -e "\nUpdating Node packages ...\n"
    npm install npm@latest -g
    npm update -g
    sudo -E env "PATH=$PATH" n stable
    npm cache verify
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
