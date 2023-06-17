#!/usr/bin/env bash
# Vim configuration

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dot_trace 'Configuring Vim ...'

os=$(uname -s)
if [ "$os" = "Linux" ] && command -V apt >/dev/null 2>&1; then
  sudo apt-get install -y build-essential cmake # build helpers
  sudo apt-get install -y python3 python3-dev python3-pip
  sudo -H pip3 install --upgrade pip setuptools
  sudo apt-get install -y vim neovim

elif [ "$os" = "Linux" ] && command -V pacman >/dev/null 2>&1; then
  sudo pacman -S --noconfirm cmake gcc # build helpers
  sudo pacman -S --noconfirm python3 python-pip
  sudo -H pip3 install --upgrade pip setuptools
  sudo pacman -S --noconfirm vim neovim

elif [ "$os" = "Darwin" ]; then
  xcode-select -p
  if [ $? != 0 ]; then
    dot_trace "Installing XCode command-line tools ..."
    xcode-select --install
  fi

  ! brew ls --versions cmake >/dev/null 2>&1 && brew install cmake
  ! brew ls --versions vim >/dev/null 2>&1 && brew install vim --with-override-system-vi --with-lua
  ! brew ls --versions neovim >/dev/null 2>&1 && brew install neovim

else
  dot_error "Unsupported OS: $os"
  return 1 >/dev/null 2>&1
  exit 1
fi

# Vim config
make_symlink "$dotdir/vim/.vim" "$HOME"
make_symlink "$dotdir/vim/.vim/.vimrc" "$HOME"
# NVim config
make_symlink "$dotdir/vim/.vim/.vimrc" "$HOME/.config/nvim" "init.vim"
make_symlink "$dotdir/vim/.vim" "$HOME/.local/share/nvim" "site"

python3 -m pip install --user --upgrade pynvim

if [ ! -f ~/.vim/autoload/plug.vim ]; then
  dot_trace 'Downloading VimPlug'
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

dot_trace 'Install & configure Vim plugins'
vim +PlugInstall +PlugUpdate +PlugUpgrade +"helptags ~/.vim/doc" +qall
dot_trace 'Install & configure NeoVim plugins'
nvim +PlugInstall +PlugUpdate +PlugUpgrade +"helptags ~/.vim/doc" +qall

dot_trace 'Configuring Vim done.'
