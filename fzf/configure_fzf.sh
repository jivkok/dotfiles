#!/usr/bin/env bash
# Configuring FZF

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

log_info "Configuring FZF ..."

if $_is_linux; then
  # apt packages are somewhat behind picking up the latest fzf. Install it from source instead. TODO: decide on Arch.
  mkdir -p "$HOME/.repos"
  fzfrepo="$HOME/.repos/fzf"

  if [ -d "$fzfrepo/.git" ]; then
    git_result=$(git -C "$fzfrepo" pull --prune)
    if [ "$git_result" = "Already up to date." ]; then
      run_install=0
    else
      run_install=1
    fi
  else
    run_install=1
    git clone --depth 1 https://github.com/junegunn/fzf "$fzfrepo"
  fi

  if [ "$run_install" = "1" ]; then
    log_trace "Running fzf install script ..."
    "$fzfrepo/install" --key-bindings --completion --no-update-rc >/dev/null
  fi

elif $_is_osx; then
  if install_or_upgrade_brew_package fzf; then
    log_trace "Running fzf install script ..."
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc >/dev/null
  fi

else
  log_error "Unsupported OS: ${_OS}"
  exit 1
fi

# fzf-git
filename="fzf-git.sh"
url="https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh"
log_trace "Downloading $url into $HOME/bin/$filename"
download_file "$url" "$HOME/bin/$filename"
chmod 755 "$HOME/bin/$filename"

log_info "Configuring FZF done."
