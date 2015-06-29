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

if [ ! -d $HOME/.vim/bundle/Vundle.vim ]; then
    git clone https://github.com/gmarik/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
fi

vim +PluginInstall +qall
