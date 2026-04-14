# shellcheck shell=bash
# Dotfiles helper functions
#
# LOG_LEVEL controls which messages are emitted (default: 2 / info).
# Set it before invoking any script to override:
#   LOG_LEVEL=3 bash setup/setup.sh   # full trace
#   LOG_LEVEL=0 bash setup/setup.sh   # errors only
#
# Levels:  0=error  1=warning  2=info  3=trace

# shellcheck disable=SC1090
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../sh/helpers.sh"

# Normalise LOG_LEVEL to a guaranteed integer once at source time.
# Falls back to 2 (info) for any unset or non-integer value (e.g. "trace" or
# "info" from a test harness that uses a different LOG_LEVEL convention).
[[ "${LOG_LEVEL:-2}" =~ ^[0-9]+$ ]] && _LOG_LEVEL="${LOG_LEVEL:-2}" || _LOG_LEVEL=2

#######################################
# Logs trace messages (level 3)
# Arguments:
#   $1 - message
# Returns:
#   None
function log_trace() {
  [ "${_LOG_LEVEL}" -lt 3 ] && return 0
  local msg="$1"
  local timestamp

  timestamp="$(date "+%Y-%m-%d %H:%M:%S")"
  echo -e "$(tput setaf 8 2>/dev/null)$timestamp: $msg$(tput sgr0 2>/dev/null)"
  echo "$timestamp: [TRACE] $msg" >>~/.dotfiles_history
}

#######################################
# Logs warning messages (level 1)
# Arguments:
#   $1 - message
# Returns:
#   None
function log_warning() {
  [ "${_LOG_LEVEL}" -lt 1 ] && return 0
  local msg="$1"
  local timestamp

  timestamp="$(date "+%Y-%m-%d %H:%M:%S")"
  echo -e "$(tput setaf 3 2>/dev/null)$timestamp: $msg$(tput sgr0 2>/dev/null)"
  echo "$timestamp: [WARNING] $msg" >>~/.dotfiles_history
}

#######################################
# Logs info messages (level 2)
# Arguments:
#   $1 - message
# Returns:
#   None
function log_info() {
  [ "${_LOG_LEVEL}" -lt 2 ] && return 0
  local msg="$1"
  local timestamp

  timestamp="$(date "+%Y-%m-%d %H:%M:%S")"
  echo -e "$(tput setaf 2 2>/dev/null)$timestamp: $msg$(tput sgr0 2>/dev/null)"
  echo "$timestamp: [INFO] $msg" >>~/.dotfiles_history
}

#######################################
# Logs errors (level 0 — always emitted)
# Arguments:
#   $1 - message
# Returns:
#   None
function log_error() {
  local msg="$1"
  local timestamp

  timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo -e "\n$(tput setaf 1 2>/dev/null)$timestamp: $msg$(tput sgr0 2>/dev/null)\n"
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
    # shellcheck disable=SC2016  # literal $1 in error message is intentional
    log_error 'Expected parameter $1 (dotfiles directory) not found.'
    return
  fi
  if [ ! -d "$1" ]; then
    log_error "Dotfiles directory not found: $1"
    return
  fi
  local dotdir="$1"

  log_trace "Pulling the latest dotfiles into $dotdir ..."

  git -C "$dotdir" pull --prune --recurse-submodules --quiet
  git -C "$dotdir" submodule update --init --recursive --quiet
}

#######################################
# Clones or updates a repo
# Arguments:
#   $1 - repository url
#   $2 - repository destination directory
# Returns:
#   None
clone_or_update_repo() {
  local repo_url="$1"
  local repo_dir="$2"

  if [ -d "$repo_dir" ]; then
    log_trace "Repository '$repo_dir' exists. Updating it."
    git -C "$repo_dir" pull --prune --recurse-submodules --quiet
    git -C "$repo_dir" submodule update --init --recursive --quiet
  else
      log_trace "Cloning '$repo_url' into '$repo_dir'."
      git clone "$repo_url" "$repo_dir"
      git -C "$repo_dir" submodule update --init --recursive --quiet
  fi
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
  local target_filename="${3:-}"

  if [ -z "$target_filename" ]; then
    target_filename=$(basename "$source")
  fi

  if [ -f "$target_directory/$target_filename" ] || [ -d "$target_directory/$target_filename" ]; then
    if [ -L "$target_directory/$target_filename" ]; then
      local symlink_pointer
      symlink_pointer=$(readlink -f "$target_directory/$target_filename")
      if [ "$symlink_pointer" = "$source" ]; then
        log_trace "Symlink ( $target_directory/$target_filename -> $source ) already exists."
        return
      fi
    fi

    local timestamp
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    log_trace "Moving $target_directory/$target_filename to $target_directory/$target_filename.$timestamp"
    mv -f "$target_directory/$target_filename" "$target_directory/$target_filename.$timestamp"
  fi

  log_trace "Creating symlink ( $target_directory/$target_filename -> $source )."
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

  log_trace "Symlinking all dotfiles from $source_directory into $target_directory ..."
  # shellcheck disable=SC2044  # dotfile names are controlled dotfiles without spaces
  for dotfile in $(find "$source_directory" -mindepth 1 -maxdepth 1 -type f -iname ".*"); do
    make_symlink "$dotfile" "$target_directory"
  done
}

#######################################
# Download a file to a destination path
# Downloads to a temp file first, then moves it to its location.
# Any extra arguments after destination path are passed directly to curl.
# Arguments:
#   $1 - URL
#   $2 - destination path
#   $@ - additional curl arguments (optional)
# Returns:
#   0 - success
#   1 - download failed
#######################################
function download_file() {
  local url="$1"
  local dest_path="$2"
  shift 2 || true
  local extra_curl_args=("$@")

  local tmp
  tmp="$(mktemp)"

  if ! curl -fsSL "${extra_curl_args[@]}" -o "$tmp" "$url"; then
    rm -f "$tmp"
    log_error "download_file: failed to download $url"
    return 1
  fi

  if [ "$tmp" != "$dest_path" ]; then
    mv -f "$tmp" "$dest_path"
  fi
}

#######################################
# Back up a file with a timestamp suffix if it exists
# Idempotent: no-op if path does not exist.
# If two backups land in the same second, a counter suffix is appended.
# Arguments:
#   $1 - file path
# Returns:
#   None
#######################################
function backup_file_if_exists() {
  local path="$1"
  if [ -f "$path" ]; then
    local timestamp
    timestamp="$(date +"%Y-%m-%d_%H-%M-%S")"
    local backup_path="$path.$timestamp"
    local count=1
    while [ -f "$backup_path" ]; do
      backup_path="$path.$timestamp.$count"
      count=$((count + 1))
    done
    log_trace "Backing up $path to $backup_path"
    cp "$path" "$backup_path"
  fi
}

#######################################
# Back up a directory with a timestamp suffix if it exists
# Idempotent: no-op if path does not exist.
# If two backups land in the same second, a counter suffix is appended.
# Arguments:
#   $1 - directory path
# Returns:
#   None
#######################################
function backup_folder_if_exists() {
  local path="$1"
  if [ -d "$path" ]; then
    local timestamp
    timestamp="$(date +"%Y-%m-%d_%H-%M-%S")"
    local backup_path="$path.$timestamp"
    local count=1
    while [ -d "$backup_path" ]; do
      backup_path="$path.$timestamp.$count"
      count=$((count + 1))
    done
    log_trace "Backing up $path to $backup_path"
    cp -r "$path" "$backup_path"
  fi
}

#######################################
# Assert that a command is present or exit with an error
# Arguments:
#   $1 - command name
# Returns:
#   None (exits 1 if command not found)
#######################################
function need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "Missing required command: $cmd"
    exit 1
  fi
}

#######################################
# Install an OSX Homebrew package if not already installed (no upgrade check).
# For use in bulk setup scripts where a global `brew upgrade` precedes install.
# Arguments:
#   $1 - package name
#   $@ - optional package arguments (passed to brew install)
# Returns:
#   0 - package was just installed
#   1 - package was already present (no action taken)
#   2 - error (invalid input or brew command failed)
#######################################
function install_brew_package() {
  local pkg_name="$1"
  shift || true
  local pkg_args=("$@")

  if [ -z "$pkg_name" ]; then
    log_error "install_brew_package: package name is required."
    return 2
  fi

  if ! brew list --versions --formula "$pkg_name" >/dev/null 2>&1; then
    if [ "${#pkg_args[@]}" -eq 0 ]; then
      brew install "$pkg_name" 2>&1
    else
      brew install "$pkg_name" "${pkg_args[@]}" 2>&1
    fi
    return 0
  fi
  return 1
}

#######################################
# Install an OSX Homebrew Cask package if not already installed (no upgrade check).
# For use in bulk setup scripts where a global `brew upgrade --cask` precedes install.
# Arguments:
#   $1 - package name
# Returns:
#   0 - package was just installed
#   1 - package was already present (no action taken)
#   2 - error (invalid input or brew command failed)
#######################################
function install_cask_package() {
  local pkg_name="$1"

  if [ -z "$pkg_name" ]; then
    log_error "install_cask_package: package name is required."
    return 2
  fi

  if ! brew list --versions --cask "$pkg_name" >/dev/null 2>&1; then
    brew install --cask "$pkg_name" 2>&1
    return 0
  fi
  return 1
}

#######################################
# Install or upgrade an OSX Homebrew package
# Arguments:
#   $1 - package name
#   $@ - optional package arguments (passed to brew install)
# Returns:
#   0 - package was installed or upgraded
#   1 - package already installed and up-to-date (no action taken)
#   2 - error (invalid input or brew command failed)
#######################################
function install_or_upgrade_brew_package() {
  local pkg_name="$1"
  shift || true
  local pkg_args=("$@")

  if [ -z "$pkg_name" ]; then
    log_error "install_or_upgrade_brew_package: package name is required."
    return 2
  fi

  if ! brew list --versions --formula "$pkg_name" >/dev/null 2>&1; then
    if [ "${#pkg_args[@]}" -eq 0 ]; then
      brew install "$pkg_name" 2>&1
    else
      brew install "$pkg_name" "${pkg_args[@]}" 2>&1
    fi

    local rc=${PIPESTATUS[0]}
    [ "$rc" -eq 0 ] && return 0 || return 2
  fi

  if brew outdated --formula --quiet "$pkg_name" | grep -q .; then
    brew upgrade --formula --quiet "$pkg_name"
    local rc=$?
    [ "$rc" -eq 0 ] && return 0 || return 2
  fi

  return 1
}

#######################################
# Install or upgrade an OSX Homebrew Cask package
# Arguments:
#   $1 - package name
#   $2 - package arguments
# Returns:
#   0 - package was installed or upgraded
#   1 - package already installed and up-to-date (no action taken)
#   2 - error (invalid input or brew command failed)
function install_or_upgrade_cask_package() {
  local pkg_name="$1"
  shift || true
  local pkg_args=("$@")

  if [ -z "$pkg_name" ]; then
    log_error "install_or_upgrade_cask_package: package name is required."
    return 2
  fi

  local installed
  installed=$(brew list --versions --cask "$pkg_name")

  if [ -z "$installed" ]; then
    if [ "${#pkg_args[@]}" -eq 0 ]; then
      brew install --cask "$pkg_name" 2>&1
    else
      brew install --cask "$pkg_name" "${pkg_args[@]}" 2>&1
    fi
    local rc=$?
    [ "$rc" -eq 0 ] && return 0 || return 2
  elif brew outdated --cask --greedy-auto-updates --quiet "$pkg_name" | grep -q .; then
    brew upgrade --cask --greedy-auto-updates --quiet "$pkg_name"
    local rc=$?
    [ "$rc" -eq 0 ] && return 0 || return 2
  fi

  return 1
}

#######################################
# Install an apt package if not already installed (no upgrade check).
# For use in bulk setup scripts where a global `apt-get upgrade` precedes install.
# Arguments:
#   $1 - package name
#   $@ - optional package arguments (passed to apt-get install)
# Returns:
#   0 - package was just installed
#   1 - package was already present (no action taken)
#   2 - error (invalid input or apt-get command failed)
#######################################
function install_apt_package() {
  local pkg_name="$1"
  shift || true
  local pkg_args=("$@")

  if [ -z "$pkg_name" ]; then
    log_error "install_apt_package: package name is required."
    return 2
  fi

  if ! dpkg -s "$pkg_name" >/dev/null 2>&1; then
    if [ "${#pkg_args[@]}" -eq 0 ]; then
      sudo apt-get install -y -qq "$pkg_name" 2>&1
    else
      sudo apt-get install -y -qq "$pkg_name" "${pkg_args[@]}" 2>&1
    fi
    return 0
  fi
  return 1
}

#######################################
# Install or upgrade an apt package
# Arguments:
#   $1 - package name
#   $@ - optional package arguments (passed to apt-get install)
# Returns:
#   0 - package was installed or upgraded
#   1 - package already installed and up-to-date (no action taken)
#   2 - error (invalid input or apt-get command failed)
#######################################
function install_or_upgrade_apt_package() {
  local pkg_name="$1"
  shift || true
  local pkg_args=("$@")

  if [ -z "$pkg_name" ]; then
    log_error "install_or_upgrade_apt_package: package name is required."
    return 2
  fi

  if ! dpkg -s "$pkg_name" >/dev/null 2>&1; then
    if [ "${#pkg_args[@]}" -eq 0 ]; then
      sudo apt-get install -y -qq "$pkg_name" 2>&1
    else
      sudo apt-get install -y -qq "$pkg_name" "${pkg_args[@]}" 2>&1
    fi
    local rc=${PIPESTATUS[0]}
    [ "$rc" -eq 0 ] && return 0 || return 2
  fi

  local installed_ver candidate_ver
  installed_ver=$(dpkg -s "$pkg_name" 2>/dev/null | grep '^Version:' | awk '{print $2}')
  candidate_ver=$(apt-cache policy "$pkg_name" 2>/dev/null | grep 'Candidate:' | awk '{print $2}')
  if [ -n "$candidate_ver" ] && [ "$installed_ver" != "$candidate_ver" ]; then
    sudo apt-get install -y -qq "$pkg_name"
    local rc=$?
    [ "$rc" -eq 0 ] && return 0 || return 2
  fi

  return 1
}

#######################################
# Install a pacman package if not already installed (no upgrade check).
# For use in bulk setup scripts where a global `pacman -Syu` precedes install.
# Arguments:
#   $1 - package name
#   $@ - optional package arguments (passed to pacman -S)
# Returns:
#   0 - package was just installed
#   1 - package was already present (no action taken)
#   2 - error (invalid input or pacman command failed)
#######################################
function install_pacman_package() {
  local pkg_name="$1"
  shift || true
  local pkg_args=("$@")

  if [ -z "$pkg_name" ]; then
    log_error "install_pacman_package: package name is required."
    return 2
  fi

  if ! pacman -Q "$pkg_name" >/dev/null 2>&1; then
    if [ "${#pkg_args[@]}" -eq 0 ]; then
      sudo pacman -S --noconfirm --needed "$pkg_name" 2>&1
    else
      sudo pacman -S --noconfirm --needed "$pkg_name" "${pkg_args[@]}" 2>&1
    fi
    return 0
  fi
  return 1
}

#######################################
# Install or upgrade a pacman package
# Arguments:
#   $1 - package name
#   $@ - optional package arguments (passed to pacman -S)
# Returns:
#   0 - package was installed or upgraded
#   1 - package already installed and up-to-date (no action taken)
#   2 - error (invalid input or pacman command failed)
#######################################
function install_or_upgrade_pacman_package() {
  local pkg_name="$1"
  shift || true
  local pkg_args=("$@")

  if [ -z "$pkg_name" ]; then
    log_error "install_or_upgrade_pacman_package: package name is required."
    return 2
  fi

  if ! pacman -Q "$pkg_name" >/dev/null 2>&1; then
    if [ "${#pkg_args[@]}" -eq 0 ]; then
      sudo pacman -S --noconfirm --needed "$pkg_name" 2>&1
    else
      sudo pacman -S --noconfirm --needed "$pkg_name" "${pkg_args[@]}" 2>&1
    fi
    local rc=${PIPESTATUS[0]}
    [ "$rc" -eq 0 ] && return 0 || return 2
  fi

  if pacman -Qu 2>/dev/null | grep -q "^${pkg_name} "; then
    sudo pacman -S --noconfirm --needed "$pkg_name"
    local rc=$?
    [ "$rc" -eq 0 ] && return 0 || return 2
  fi

  return 1
}

#######################################
# Install a yay (AUR) package if not already installed (no upgrade check).
# For use in bulk setup scripts where a global `yay -Syu` precedes install.
# Arguments:
#   $1 - package name
#   $@ - optional package arguments (passed to yay -S)
# Returns:
#   0 - package was just installed
#   1 - package was already present (no action taken)
#   2 - error (invalid input or yay command failed)
#######################################
function install_yay_package() {
  local pkg_name="$1"
  shift || true
  local pkg_args=("$@")

  if [ -z "$pkg_name" ]; then
    log_error "install_yay_package: package name is required."
    return 2
  fi

  if ! yay -Q "$pkg_name" >/dev/null 2>&1; then
    if [ "${#pkg_args[@]}" -eq 0 ]; then
      yay -S --noconfirm "$pkg_name" 2>&1
    else
      yay -S --noconfirm "$pkg_name" "${pkg_args[@]}" 2>&1
    fi
    return 0
  fi
  return 1
}

#######################################
# Install or upgrade a yay (AUR) package
# Arguments:
#   $1 - package name
#   $@ - optional package arguments (passed to yay -S)
# Returns:
#   0 - package was installed or upgraded
#   1 - package already installed and up-to-date (no action taken)
#   2 - error (invalid input or yay command failed)
#######################################
function install_or_upgrade_yay_package() {
  local pkg_name="$1"
  shift || true
  local pkg_args=("$@")

  if [ -z "$pkg_name" ]; then
    log_error "install_or_upgrade_yay_package: package name is required."
    return 2
  fi

  if ! yay -Q "$pkg_name" >/dev/null 2>&1; then
    if [ "${#pkg_args[@]}" -eq 0 ]; then
      yay -S --noconfirm "$pkg_name" 2>&1
    else
      yay -S --noconfirm "$pkg_name" "${pkg_args[@]}" 2>&1
    fi
    local rc=${PIPESTATUS[0]}
    [ "$rc" -eq 0 ] && return 0 || return 2
  fi

  if yay -Qu 2>/dev/null | grep -q "^${pkg_name} "; then
    yay -S --noconfirm "$pkg_name"
    local rc=$?
    [ "$rc" -eq 0 ] && return 0 || return 2
  fi

  return 1
}

#######################################
# Install or upgrade a global NPM package
# Arguments:
#   $1 - package name
# Returns:
#   None
function install_or_upgrade_npm_package() {
  local pkg_name="$1"

  if [ -z "$pkg_name" ]; then
    log_error "install_or_upgrade_npm_package: package name is required."
    return
  fi

  if ! npm list -g --depth=0 "$pkg_name" >/dev/null; then
    npm install -g --no-fund "$pkg_name"
  fi
}

function ver {
  # shellcheck disable=SC2046,SC2183  # word splitting intentional: tr splits "a.b.c.d" into 4 tokens for printf
  printf "%04d%04d%04d%04d" $(echo "$1" | tr '.' ' ')
}

#######################################
# Appends/merge content of a file into another
# Arguments:
#   $1 - source file
#   $2 - target file
# Returns:
#   None
append_or_merge_file() {
  local source_file="$1"
  local target_file="$2"

  if [ ! -f "$target_file" ]; then
    log_trace "Copying '$source_file' into '$target_file'"
    cp "$source_file" "$target_file"
  else
    local changed=0
    while IFS= read -r line; do
      if ! grep -Fxq "$line" "$target_file"; then
        echo "$line" >> "$target_file"
        changed=1
      fi
    done < "$source_file"
    if [ "$changed" -eq 1 ]; then
      log_trace "Merging '$source_file' into '$target_file': changes applied."
    else
      log_trace "Merging '$source_file' into '$target_file': already up-to-date, no changes."
    fi
  fi
}
