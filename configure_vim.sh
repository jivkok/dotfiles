#!/bin/bash
# Vim configuration

# $1 - message
function echo2 ()
{
    echo -e "\n$1\n"
}

# dotfiles refresh
if [ -d "$HOME/dotfiles/.git" ]; then
    echo2 'Refreshing dotfiles.'
    git -C "$HOME/dotfiles" pull --prune --recurse-submodules
    git -C "$HOME/dotfiles" submodule update --init --recursive
fi

echo2 'Configuring Vim ...'

os=$(uname -s)

if [ "$os" = "Linux" ]; then
    sudo add-apt-repository ppa:neovim-ppa/unstable
    sudo apt-get update

    sudo apt-get install build-essential
    sudo apt-get install cmake
    sudo apt-get install python-dev python-pip python3-dev python3-pip
    sudo apt-get install vim
    sudo apt-get install neovim

    sudo pip2 install --upgrade neovim
    sudo pip3 install --upgrade neovim
elif [ "$os" = "Darwin" ]; then
    xcode-select -p
    if [ $? != 0 ]; then
        xcode-select --install
    fi
    brew install cmake
    # brew install llvm --with-clang
    brew install vim --override-system-vi --with-lua
    brew install macvim --HEAD --with-cscope --with-lua --with-override-system-vim --with-luajit --with-python
    brew install neovim/neovim/neovim

    pip2 install --upgrade neovim
    pip3 install --upgrade neovim
else
    echo2 "Unsupported OS: $os"
    return
fi

echo2 'Downloading VimPlug'
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo2 'Install & configure Vim plugins.'
v +PlugInstall +PlugUpdate +PlugUpgrade +"helptags ~/.vim/doc" +qall

# YouCompleteMe post-install configuration
# Refer to https://github.com/Valloric/YouCompleteMe if issues occur
ycmdir="$HOME/.vim/plugins/YouCompleteMe"
if [ -d "$ycmdir" ]; then
    if [ "$os" = "Linux" ] || [ "$os" = "Darwin" ] ; then
        echo2 'Configuring YouCompleteMe ...'

        echo "Support for:"
        local supportC supportCsharp supportGo supportJavascript
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
            "$ycmdir/install.py" $supportC $supportCsharp $supportGo $supportJavascript
        fi
        echo2 'Configuring YouCompleteMe done.'
    else
        echo2 "Warning: Configuring YouCompleteMe for $os not supported yet."
    fi
fi

echo2 'Configuring Vim done.'
