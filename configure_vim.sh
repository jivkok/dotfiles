#!/bin/bash
# Vim configuration

# dotdir="$( cd "$( dirname "$0" )" && pwd )"
[ -z "$dotdir" ] && dotdir="$HOME/dotfiles"

source "$dotdir/setupfunctions.sh"
pull_latest_dotfiles "$dotdir"

dot_trace 'Configuring Vim ...'

mkdir -p "$HOME/.config"
make_symlink "$dotdir/.vim" "$HOME"
make_symlink "$dotdir/.vim" "$HOME/.config" "nvim"
make_symlink "$dotdir/.vim/.vimrc" "$HOME"

os=$(uname -s)
if [ "$os" = "Linux" ]; then
    sudo apt-get install -y build-essential
    sudo apt-get install -y cmake
    sudo apt-get install -y python3-dev python3-pip
    sudo apt-get install -y vim
    sudo apt-get install -y neovim
elif [ "$os" = "Darwin" ]; then
    xcode-select -p
    if [ $? != 0 ]; then
        dot_trace "Installing XCode command-line tools ..."
        xcode-select --install
    fi

    ! brew ls --versions cmake >/dev/null 2>&1 && brew install cmake
    # brew install llvm --with-clang
    ! brew ls --versions vim >/dev/null 2>&1 && brew install vim --with-override-system-vi --with-lua
    ! brew ls --versions macvim >/dev/null 2>&1 && brew install macvim --HEAD --with-cscope --with-lua --with-override-system-vim --with-luajit --with-python
    ! brew ls --versions neovim >/dev/null 2>&1 && brew install neovim/neovim/neovim
else
    dot_trace "Unsupported OS: $os"
    return
fi

sudo -H python3 -m pip install --upgrade neovim

if [ ! -f ~/.vim/autoload/plug.vim ] ; then
    dot_trace 'Downloading VimPlug'
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

dot_trace 'Install & configure Vim plugins'
vim +PlugInstall +PlugUpdate +PlugUpgrade +"helptags ~/.vim/doc" +qall
dot_trace 'Install & configure NeoVim plugins'
nvim +PlugInstall +PlugUpdate +PlugUpgrade +"helptags ~/.vim/doc" +qall

# YouCompleteMe post-install configuration
# Refer to https://github.com/Valloric/YouCompleteMe if issues occur
ycmdir="$HOME/.vim/plugins/YouCompleteMe"
if [ -d "$ycmdir" ]; then
    if [ "$os" = "Linux" ] || [ "$os" = "Darwin" ] ; then
        dot_trace 'Configuring YouCompleteMe ...'

        echo "YouCompleteMe support for:"
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

        # export EXTRA_CMAKE_ARGS="-DEXTERNAL_LIBCLANG_PATH=/Library/Developer/CommandLineTools/usr/lib/libclang.dylib"
        "$ycmdir/install.py" $supportC $supportCsharp $supportGo $supportJavascript

        dot_trace 'Configuring YouCompleteMe done.'
    else
        dot_error "Configuring YouCompleteMe for $os not supported yet."
    fi
fi

dot_trace 'Configuring Vim done.'
