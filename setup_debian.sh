#!/bin/bash
# Configuring Linux environment (Debian-style)

# $1 - file, $2 - message
function ask_and_run ()
{
    if [ ! -f $1 ]; then return; fi
    shh=$(ps -p $$ -oargs=)
    if [ "-zsh" = $shh ]; then
        read "REPLY?$2 "
    else
        read -p "$2 " -n 1 -r
    fi
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then return; fi

    source $1

    return
}

cd $HOME

# dotfiles
if [ -d dotfiles/.git ]; then
    cd dotfiles
    git pull --prune --recurse-submodules
    git submodule init
    git submodule update --remote --recursive
    cd ..
else
    if [ -d dotfiles ]; then
        mv dotfiles dotfiles.old
    fi
    git clone --recursive https://github.com/jivkok/dotfiles.git dotfiles
fi

ln -sf dotfiles/.vim .
ln -sb dotfiles/.aliases .
ln -sb dotfiles/.bash_profile .
ln -sb dotfiles/.bash_prompt .
ln -sb dotfiles/.bashrc .
ln -sb dotfiles/.curlrc .
ln -sb dotfiles/.exports .
ln -sb dotfiles/.functions .
ln -sb dotfiles/.tmux.conf .
ln -sb dotfiles/.vim/.vimrc .
ln -sb dotfiles/.wgetrc .
curl -o git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

ask_and_run dotfiles/linux/packages.sh "Would you like to install system packages?"

ask_and_run dotfiles/linux/software.sh "Would you like to install GUI packages?"

ask_and_run dotfiles/configure_git.sh "Would you like to configure Git?"

ask_and_run dotfiles/configure_zsh.sh "Would you like to install and configure ZSH?"

ask_and_run dotfiles/configure_python.sh "Would you like to configure Python (plus packages)?"

ask_and_run dotfiles/configure_ruby.sh "Would you like to configure Ruby (plus packages)?"

ask_and_run dotfiles/configure_vim.sh "Would you like to install and configure Vim?"

ask_and_run dotfiles/configure_sublimetext.sh "Would you like to configure SublimeText?"

echo "Done"
