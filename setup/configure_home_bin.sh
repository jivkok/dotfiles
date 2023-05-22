#!/usr/bin/env bash
# Configure HOME bin directory content

function download_to_home_bin() {
  local filename="$1"
  local download_url="$2"

  dot_trace "Download: $download_url"
  curl -s -o "$HOME/bin/$filename" "$download_url"
  chmod 755 "$HOME/bin/$filename"
}

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Configuring HOME bin directory ..."

mkdir -p "$HOME/bin"

# download_to_home_bin "git-prompt.sh" "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh"
download_to_home_bin "diff-so-fancy" "https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy"
download_to_home_bin "prettyping" "https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping"

dot_trace "Configuring HOME bin directory done."
