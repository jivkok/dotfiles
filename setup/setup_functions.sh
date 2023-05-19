#!/usr/bin/env bash
# Setup helper functions

#######################################
# Logs traces from dotfiles scripts
# Arguments:
#   $1 - message
# Returns:
#   None
function dot_trace() {
  local msg="$1"
  local timestamp

  timestamp="$(date "+%Y-%m-%d %H:%M:%S")"
  echo -e "$(tput setaf 2)$timestamp: $msg$(tput sgr0)"
  touch ~/.dotfiles_history
  echo "$timestamp: [INFO] $msg" >>~/.dotfiles_history
}

#######################################
# Logs errors from dotfiles scripts
# Arguments:
#   $1 - message
# Returns:
#   None
function dot_error() {
  local msg="$1"
  local timestamp

  timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo -e "\n$(tput setaf 1)$timestamp: $msg$(tput sgr0)\n"
  echo "$timestamp: [ERROR] $msg" >>~/.dotfiles_history
}

#######################################
# Pull latest dotfiles from its remote repo
# Arguments:
#   $1 - dotfiles directory
# Returns:
#   None
function pull_latest_dotfiles() {
  if [ -z "$1" ]; then
    dot_error 'Expected parameter $1 (dotfiles directory) not found.'
    return
  fi
  if [ ! -d "$1" ]; then
    dot_error "Dotfiles directory not found: $1"
    return
  fi
  local dotdir="$1"

  dot_trace "Pulling the latest dotfiles into $dotdir ..."

  git -C "$dotdir" pull --prune --recurse-submodules
  git -C "$dotdir" submodule update --init --recursive
}

#######################################
# Clones or updates a repo
# Arguments:
#   $1 - repository url
#   $2 - repository destination directory
# Returns:
#   None
clone_or_update_repo() {
  repo_url="$1"
  repo_dir="$2"

  if [ -d "$repo_dir" ]; then
    dot_trace "Repository '$repo_dir' exists. Updating it."
    git -C "$repo_dir" pull --prune --recurse-submodules
    git -C "$repo_dir" submodule update --init --recursive
  else
      dot_trace "Cloning '$repo_url' into '$repo_dir'."
      git clone "$repo_url" "$repo_dir"
      git -C "$repo_dir" submodule update --init --recursive
  fi
}

#######################################
# Asks for confirmation running a script, and runs it if affirmative
# Arguments:
#   $1 - script
#   $2 - script description
# Returns:
#   None
function confirm_and_run() {
  local shh
  shh="$(ps -p $$ -oargs=)"
  if [[ "$shh" == *zsh* ]]; then
    read -r "REPLY?Would you like to configure $2 ? "
  else
    read -r -n 1 -p "Would you like to configure $2 ? " </dev/tty
  fi
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then return; fi

  echo
  # shellcheck source=/dev/null
  source "$1"
  echo
}

#######################################
# Make symlinks between files (and take backup if needed)
# Arguments:
#   $1 - source file/directory
#   $2 - target directory
#   $3 - target filename (optional)
# Returns:
#   None
function make_symlink() {
  local source="$1"
  local target_directory="$2"
  local target_filename="$3"

  if [ -z "$target_filename" ]; then
    target_filename=$(basename "$source")
  fi

  if [ -f "$target_directory/$target_filename" ] || [ -d "$target_directory/$target_filename" ]; then
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    dot_trace "Moving $target_directory/$target_filename to $target_directory/$target_filename.$timestamp"
    mv -f "$target_directory/$target_filename" "$target_directory/$target_filename.$timestamp"
  fi

  mkdir -p "$target_directory"
  ln -s -f "$source" "$target_directory/$target_filename"
}

#######################################
# Make symlinks for all dotfiles in a directory
# Arguments:
#   $1 - source directory
#   $2 - target directory
# Returns:
#   None
function make_dotfiles_symlinks() {
  local source_directory="$1"
  local target_directory="$2"

  dot_trace "Symlinking all dotfiles from $source_directory into $target_directory ..."
  for dotfile in $(find "$source_directory" -mindepth 1 -maxdepth 1 -type f -iname ".*"); do
    dot_trace "- dotfile: $dotfile"
    make_symlink "$dotfile" "$target_directory"
  done
}

#######################################
# Install OSX HomeBrew package
# Arguments:
#   $1 - package name
#   $2 - package arguments
# Returns:
#   None
function brew_install_package() {
  local pkg_name="$1"
  local pkg_args="$2"

  if [ -z "$pkg_name" ]; then
    dot_error "brew_install_package: package name is required."
    return
  fi

  if brew ls --versions "$pkg_name" >/dev/null 2>&1; then
    dot_trace "$pkg_name is already installed."
  fi

  if [ -z "$pkg_args" ]; then
    brew install "$pkg_name" 2>&1 | tee ~/.dotfiles_history
  else
    brew install "$pkg_name" "$pkg_args" 2>&1 | tee ~/.dotfiles_history
  fi
}

#######################################
# Install OSX HomeBrew Cask package
# Arguments:
#   $1 - package name
#   $2 - package arguments
# Returns:
#   None
function cask_install_package() {
  local pkg_name="$1"
  local pkg_args="$2"

  if [ -z "$pkg_name" ]; then
    dot_error "cask_install_package: package name is required."
    return
  fi

  if brew cask ls --versions "$pkg_name" >/dev/null 2>&1; then
    dot_trace "$pkg_name is already installed."
    return
  fi

  if [ -z "$pkg_args" ]; then
    brew cask install "$pkg_name" 2>&1 | tee ~/.dotfiles_history
  else
    brew cask install "$pkg_name" "$pkg_args" 2>&1 | tee ~/.dotfiles_history
  fi
}

function ver {
  printf "%04d%04d%04d%04d" "$(echo "$1" | tr '.' ' ')"
}

#######################################
# Appends/merge content of a file into another
# Arguments:
#   $1 - source file
#   $2 - target file
# Returns:
#   None
append_or_merge_file() {
  source_file="$1"
  target_file="$2"

  if [ ! -f "$target_file" ]; then
    dot_trace "Copying '$source_file' into '$target_file'"
    cp "$source_file" "$target_file"
  else
    dot_trace "Merging '$source_file' into '$target_file'"
    while IFS= read -r line; do
      if ! grep -Fxq "$line" "$target_file"; then
        echo "$line" >> "$target_file"
      fi
    done < "$source_file"
  fi
}
