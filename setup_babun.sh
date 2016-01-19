#!/bin/bash
# Configure Windows environment (Babun distro for Cygwin)

echo "Configuring Windows environment (Babun distro for Cygwin) ..."

# Packages
pact update
pact install tmux

# dotfiles
dotdir="$HOME/dotfiles"

if [ -d "$dotdir/.git" ]; then
    git -C "$dotdir" pull --prune --recurse-submodules
else
    if [ -d "$dotdir" ]; then
        mv "$dotdir" "${dotdir}.old"
    fi
    git clone --recursive https://github.com/jivkok/dotfiles.git "$dotdir"
fi
git -C "$dotdir" submodule update --init --recursive

[ -d "$HOME/.vim" ] && mv "$HOME/.vim" "$HOME/.vim~"
ln -sf "$dotdir/.vim" "$HOME/"
ln -sb "$dotdir/.aliases" "$HOME/"
ln -sb "$dotdir/.bash_profile" "$HOME/"
ln -sb "$dotdir/.bash_prompt" "$HOME/"
ln -sb "$dotdir/.bashrc" "$HOME/"
ln -sb "$dotdir/.curlrc" "$HOME/"
ln -sb "$dotdir/.exports" "$HOME/"
ln -sb "$dotdir/.functions" "$HOME/"
ln -sb "$dotdir/.tmux.conf" "$HOME/"
ln -sb "$dotdir/.vim/.vimrc" "$HOME/"
ln -sb "$dotdir/.wgetrc" "$HOME/"
curl -o "$HOME/git-prompt.sh" https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

# Git
[ -f "$dotdir/configure_git.sh" ] && source "$dotdir/configure_git.sh"

mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ] && git clone git://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
ln -sb "$dotdir/.zprofile" "$HOME/"
ln -sb "$dotdir/.zshrc" "$HOME/"
ln -sb "$dotdir/.zsh-theme" "$HOME/"

source "$HOME/.zprofile"
source "$HOME/.zshrc"

echo "Configuring Windows environment (Babun distro for Cygwin) done."
