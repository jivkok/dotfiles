#!/usr/bin/env bash
# Configuring FZF

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Configuring FZF ..."

os=$(uname -s)
if [ "$os" = "Linux" ] >/dev/null 2>&1; then
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
    "$fzfrepo/install" --key-bindings --completion --no-update-rc
  fi

elif [ "$os" = "Darwin" ]; then
  ! brew ls --versions fzf >/dev/null 2>&1 && brew install fzf

  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc >/dev/null

else
  dot_error "Unsupported OS: $os"
  return 1 >/dev/null 2>&1
  exit 1
fi

# fzf-git
filename="fzf-git.sh"
url="https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh"
dot_trace "Downloading $url into $HOME/bin/$filename"
curl -s -o "$HOME/bin/$filename" "$url"
chmod 755 "$HOME/bin/$filename"

dot_trace "Configuring FZF done."
