#!/bin/bash
# Vim configuration

# $1 - message
function echo2 ()
{
    echo -e "\n$1\n"
}

echo2 'Configuring Vim ...'

os=$(uname -s)

if [ "$os" = "Linux" ]; then
    sudo apt-get install build-essential
    sudo apt-get install cmake
    sudo apt-get install python-dev
    sudo apt-get install vim
elif [ "$os" = "Darwin" ]; then
    xcode-select -p
    if [ $? != 0 ]; then
        xcode-select --install
    fi
    brew install cmake
    # brew install llvm --with-clang
    brew install vim --override-system-vi
else
    echo2 "Unsupported OS: $os"
    return
fi

# dotfiles check - Vundle.vim should be included as a submodule
if [ -d "$HOME/dotfiles/.git" ]; then
    echo2 'Refreshing dotfiles.'
    git -C "$HOME/dotfiles" pull origin master --recurse-submodules
    git -C "$HOME/dotfiles" submodule init
    git -C "$HOME/dotfiles" submodule update --remote --recursive
fi
if [ ! -d "$HOME/.vim/bundle/Vundle.vim" ]; then
    git clone https://github.com/gmarik/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"
fi

echo2 'Install & configure Vim plugins.'
vim +PluginInstall +"helptags ~/.vim/doc" +qall

# YouCompleteMe post-install configuration
# Refer to https://github.com/Valloric/YouCompleteMe if issues occur
if [ -d "$HOME/.vim/bundle/YouCompleteMe" ]; then
    echo2 'Configuring YouCompleteMe ...'
    if [ "$os" = "Linux" ]; then
        cd $HOME/.vim/bundle/YouCompleteMe
        # export EXTRA_CMAKE_ARGS="-DEXTERNAL_LIBCLANG_PATH=/Library/Developer/CommandLineTools/usr/lib/libclang.dylib"
        ./install.py --clang-completer --omnisharp-completer
        cd $HOME
    elif [ "$os" = "Darwin" ]; then
        cd $HOME/.vim/bundle/YouCompleteMe
        # export EXTRA_CMAKE_ARGS="-DEXTERNAL_LIBCLANG_PATH=/Library/Developer/CommandLineTools/usr/lib/libclang.dylib"
        ./install.py --clang-completer --omnisharp-completer
        cd $HOME
    fi
    echo2 'Configuring YouCompleteMe done.'
fi

echo2 'Configuring Vim done.'
