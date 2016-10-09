#!/bin/bash
# Configure Linux environment (Debian-style)

echo "Configuring Linux environment (Debian-style) ..."

# $1 - file, $2 - message
function ask_and_run ()
{
    if [ ! -f "$1" ]; then return; fi
    shh=$(ps -p $$ -oargs=)
    if [ "-zsh" = "$shh" ]; then
        read -r "REPLY?$2 "
    else
        read -p "$2 " -n 1 -r
    fi
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then return; fi

    source "$1"

    return
}

# dotfiles
dotdir="$HOME/dotfiles"

if [ -d "$dotdir/.git" ]; then
    git -C "$dotdir" pull --prune --recurse-submodules
    git -C "$dotdir" submodule update --init --recursive
else
    if [ -d "$dotdir" ]; then
        mv "$dotdir" "${dotdir}.old"
    fi
    git clone --recursive https://github.com/jivkok/dotfiles.git "$dotdir"
fi

mkdir -p "$HOME/.config"

ln -sf "$dotdir/.vim" "$HOME/"
ln -sf "$dotdir/.vim" "$HOME/.config/nvim"
ln -sb "$dotdir/.aliases" "$HOME/"
ln -sb "$dotdir/.bash_profile" "$HOME/"
ln -sb "$dotdir/.bash_prompt" "$HOME/"
ln -sb "$dotdir/.bashrc" "$HOME/"
ln -sb "$dotdir/.curlrc" "$HOME/"
ln -sb "$dotdir/.editorconfig" "$HOME/"
ln -sb "$dotdir/.exports" "$HOME/"
ln -sb "$dotdir/.functions" "$HOME/"
ln -sb "$dotdir/.marks.sh" "$HOME/"
ln -sb "$dotdir/.tmux.conf" "$HOME/"
ln -sb "$dotdir/.vim/.vimrc" "$HOME/"
ln -sb "$dotdir/.wgetrc" "$HOME/"

curl -o "$HOME/git-prompt.sh" https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

ask_and_run "$dotdir/linux/packages.sh" "Would you like to install system packages?"

ask_and_run "$dotdir/linux/software.sh" "Would you like to install GUI packages?"

ask_and_run "$dotdir/configure_git.sh" "Would you like to configure Git?"

ask_and_run "$dotdir/configure_zsh.sh" "Would you like to install and configure ZSH?"

ask_and_run "$dotdir/configure_python.sh" "Would you like to configure Python (plus packages)?"

ask_and_run "$dotdir/configure_nodejs.sh" "Would you like to configure NodeJS (plus packages)?"

ask_and_run "$dotdir/configure_ruby.sh" "Would you like to configure Ruby (plus packages)?"

ask_and_run "$dotdir/configure_vim.sh" "Would you like to install and configure Vim?"

ask_and_run "$dotdir/configure_sublimetext.sh" "Would you like to configure SublimeText?"

echo "Configuring Linux environment (Debian-style) done."
