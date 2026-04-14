#!/usr/bin/env bash
# Configure HOME bin directory content

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

log_info "Configuring HOME bin directory ..."

mkdir -p "$HOME/bin"

# download_file "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh" "$HOME/bin/git-prompt.sh"
# download_file "https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy" "$HOME/bin/diff-so-fancy"
# download_file "https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping" "$HOME/bin/prettyping"

if [ ! -L "$HOME/bin/bat" ] && [ -f "/usr/bin/batcat" ]; then
  make_symlink "/usr/bin/batcat" "$HOME/bin" "bat"
fi
if [ ! -L "$HOME/bin/fd" ] && [ -f "/usr/lib/cargo/bin/fd" ]; then
  make_symlink "/usr/lib/cargo/bin/fd" "$HOME/bin"
fi

log_info "Configuring HOME bin directory done."
