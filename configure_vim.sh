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
    brew install macvim --HEAD --with-cscope --with-lua --with-override-system-vim --with-luajit --with-python
else
    echo2 "Unsupported OS: $os"
    return
fi

# dotfiles check - Vundle.vim should be included as a submodule
if [ -d "$HOME/dotfiles/.git" ]; then
    echo2 'Refreshing dotfiles.'
    git -C "$HOME/dotfiles" pull origin master --recurse-submodules
    git -C "$HOME/dotfiles" submodule update --init --recursive
fi
if [ ! -d "$HOME/.vim/bundle/Vundle.vim" ]; then
    git clone https://github.com/gmarik/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"
fi

echo2 'Install & configure Vim plugins.'
vim +PluginInstall +"helptags ~/.vim/doc" +qall

# YouCompleteMe post-install configuration
# Refer to https://github.com/Valloric/YouCompleteMe if issues occur
if [ -d "$HOME/.vim/bundle/YouCompleteMe" ]; then
    if [ "$os" = "Linux" ] || [ "$os" = "Darwin" ] ; then
        echo2 'Configuring YouCompleteMe ...'

        echo "Support for:"
        local supportC, supportCsharp, supportGo, supportJavascript
        supportC="--clang-completer"
        supportCsharp="--omnisharp-completer"
        echo "- C-family: yes"
        echo "- C#: yes"

        if command -v go >/dev/null 2>&1 ; then
            supportGo="--gocode-completer"
            echo "- Go: yes"
        else
            echo "- Go: no"
        fi

        if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1 ; then
            supportJavascript="--tern-completer"
            echo "- JavaScript: yes"
        else
            echo "- JavaScript: no"
        fi

        if [ "$os" = "Linux" ] || [ "$os" = "Darwin" ] ; then
            # export EXTRA_CMAKE_ARGS="-DEXTERNAL_LIBCLANG_PATH=/Library/Developer/CommandLineTools/usr/lib/libclang.dylib"
            "$HOME/.vim/bundle/YouCompleteMe/install.py" $supportC $supportCsharp $supportGo $supportJavascript
        fi
        echo2 'Configuring YouCompleteMe done.'
    else
        echo2 'Warning: Configuring YouCompleteMe for $os not supported yet.'
    fi
fi

echo2 'Configuring Vim done.'
