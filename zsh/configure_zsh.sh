#!/usr/bin/env bash
# Configure ZSH

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Configuring ZSH ..."

os=$(uname -s)
if [ "$os" = "Linux" ] && command -V apt >/dev/null 2>&1; then
  if ! dpkg -s zsh >/dev/null 2>&1; then
    dot_trace "Installing ZSH ..."
    sudo apt-get install -y zsh
    dot_trace "Installing ZSH done."
  fi

elif [ "$os" = "Linux" ] && command -V pacman >/dev/null 2>&1; then
  sudo pacman -S --noconfirm zsh

elif [ "$os" = "Darwin" ]; then
  if ! brew ls --versions zsh >/dev/null 2>&1; then
    dot_trace "Installing ZSH ..."
    brew install zsh
    dot_trace "Installing ZSH done."
  else
    dot_trace "Updating ZSH ..."
    brew upgrade zsh
    dot_trace "Updating ZSH done."
  fi

else
  dot_trace "Unsupported OS: $os"
  return 1 >/dev/null 2>&1
  exit 1
fi

dot_trace "Installing zsh plugins ..."
zpluginsdir="$HOME/.zsh/plugins"
mkdir -p "$zpluginsdir"
clone_or_update_repo "https://github.com/zsh-users/zsh-autosuggestions" "$zpluginsdir/zsh-autosuggestions"
clone_or_update_repo "https://github.com/zsh-users/zsh-completions" "$zpluginsdir/zsh-completions"
clone_or_update_repo "https://github.com/zsh-users/zsh-syntax-highlighting" "$zpluginsdir/zsh-syntax-highlighting"
dot_trace "Installing zsh plugins done."

_zsh=$(command -v zsh)

if [ -z "$(grep "$_zsh" /etc/shells)" ]; then
  dot_trace "Adding ZSH as supported shell"
  echo "$_zsh" | sudo tee -a /etc/shells
else
  dot_trace "Check: ZSH is supported shell"
fi

if [ "$SHELL" != "$_zsh" ]; then
  dot_trace "Switching to ZSH as default shell"
  [ -f /etc/pam.d/chsh ] && sudo sed -ir 's/^\(auth\)\s\+\(required\)\s\+\(pam_shells\.so\)/\1 sufficient \3/' /etc/pam.d/chsh
  chsh -s "$_zsh"
else
  dot_trace "Check: ZSH is default shell"
fi

unset _zsh

dot_trace "Configuring ZSH done."
