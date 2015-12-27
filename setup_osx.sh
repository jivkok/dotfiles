#!/bin/bash
# Configure OSX environment

echo "Configuring OSX environment ..."

# $1 - file, $2 - message
function ask_and_run ()
{
    if [ ! -f "$1" ]; then return; fi
    shh=$(ps -p $$ -oargs=)
    if [ "-zsh" = "$shh" ]; then
        read -r "REPLY?$2 "
    else
        read -r -p "$2 " -n 1
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

ln -sF "$dotdir/.vim" "$HOME/"
ln -sf "$dotdir/.aliases" "$HOME/"
ln -sf "$dotdir/.bash_profile" "$HOME/"
ln -sf "$dotdir/.bash_prompt" "$HOME/"
ln -sf "$dotdir/.bashrc" "$HOME/"
ln -sf "$dotdir/.exports" "$HOME/"
ln -sf "$dotdir/.functions" "$HOME/"
ln -sf "$dotdir/.tmux.conf" "$HOME/"
ln -sf "$dotdir/.vim/.vimrc" "$HOME/"
ln -sf "$dotdir/.wgetrc" "$HOME/"
ln -sf "$dotdir/osx/.duti" "$HOME/"
curl -o "$HOME/git-prompt.sh" https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

# Command-line tools (must be first since it installs gcc)
xcode-select -p
if [ $? != 0 ]; then
    read -p "Would you like to install the XCode command-line tools?" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        xcode-select --install
    fi
fi

ask_and_run "$dotdir/osx/brew.sh" "Would you like to install system packages?"

ask_and_run "$dotdir/osx/software.sh" "Would you like to install GUI packages?"

ask_and_run "$dotdir/configure_git.sh" "Would you like to configure Git?"

ask_and_run "$dotdir/configure_zsh.sh" "Would you like to configure Zsh?"

ask_and_run "$dotdir/configure_python.sh" "Would you like to configure Python (plus packages)?"

ask_and_run "$dotdir/configure_ruby.sh" "Would you like to configure Ruby (plus packages)?"

ask_and_run "$dotdir/configure_vim.sh" "Would you like to configure Vim?"

ask_and_run "$dotdir/configure_sublimetext.sh" "Would you like to configure SublimeText?"

ask_and_run "$dotdir/configure_brackets.sh" "Would you like to configure Brackets?"

ask_and_run "$dotdir/osx/.osx" "Would you like to set sensible OSX defaults?"

ask_and_run "$dotdir/osx/alfred.sh" "Would you like to configure Alfred?"

ask_and_run "$dotdir/osx/dotnet.sh" "Would you like to configure DotNet?"

echo "Configuring OSX environment done."
