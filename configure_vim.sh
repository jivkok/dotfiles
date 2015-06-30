#!/bin/bash
# Configuring Vim

os=$(uname -s)
if [ "$os" = "Linux" ]; then
    sudo apt-get install vim
elif [ "$os" = "Darwin" ]; then
    brew install vim --override-system-vi
else
    echo "Unsupported OS: $os"
    return
fi

cd $HOME

# dotfiles check - Vundle.vim should be included as a submodule
if [ -d dotfiles/.git ]; then
    cd dotfiles
    git pull origin master --recurse-submodules
    git submodule init
    git submodule update --remote --recursive
    cd ..
fi

if [ ! -d $HOME/.vim/bundle/Vundle.vim ]; then
    git clone https://github.com/gmarik/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
fi

vim +PluginInstall +qall
