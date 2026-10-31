# shellcheck shell=bash

export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
dotdir="$DOTFILES"
source "$dotdir/zsh/setenv.sh"
[ -r "$HOME/bin/fzf-git.sh" ] && [ -f "$HOME/bin/fzf-git.sh" ] && source "$HOME/bin/fzf-git.sh";
[ -r "$HOME/.profile_local.sh" ] && [ -f "$HOME/.profile_local.sh" ] && source "$HOME/.profile_local.sh";
