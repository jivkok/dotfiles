#!/usr/bin/env bash
# Configuring FZF

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Configuring FZF ..."

mkdir -p "$HOME/.repos"
fzfrepo="$HOME/.repos/fzf"

# FZF
if [ -d "$fzfrepo/.git" ]; then
  git -C "$fzfrepo" pull --prune
else
  git clone --depth 1 https://github.com/junegunn/fzf "$fzfrepo"
fi
"$fzfrepo/install" --key-bindings --completion --no-update-rc

# fzf-git
filename="fzf-git.sh"
url="https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh"
echo "Downloading $url"
curl -s -o "$HOME/bin/$filename" "$url"
chmod 755 "$HOME/bin/$filename"

dot_trace "Configuring FZF done."
