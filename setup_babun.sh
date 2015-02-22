#!/bin/bash
# Configuring Windows environment (Babun distro for Cygwin)

# Packages
pact update
pact install tmux

cd $HOME

# dotfiles
if [ -d dotfiles/.git ]; then
    cd dotfiles
    git pull origin master
    git submodule update --remote
    cd ..
else
    if [ -d dotfiles ]; then
        mv dotfiles dotfiles.old
    fi
    git clone --recursive https://github.com/jivkok/dotfiles.git dotfiles
fi

ln -sb dotfiles/.aliases .
ln -sb dotfiles/.bash_profile .
ln -sb dotfiles/.bash_prompt .
ln -sb dotfiles/.bashrc .
ln -sb dotfiles/.curlrc .
ln -sb dotfiles/.exports .
ln -sb dotfiles/.functions .
ln -sb dotfiles/.tmux.conf .
ln -sb dotfiles/.wgetrc .
curl -o git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

# Git
[ -f ~/dotfiles/configure_git.sh ] && source ~/dotfiles/configure_git.sh

mkdir -p ~/.oh-my-zsh/custom/plugins
[ ! -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ] && git clone git://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
ln -sb dotfiles/.zprofile .
ln -sb dotfiles/.zshrc .
ln -sb dotfiles/.zsh-theme .

echo "Done"
