#!/usr/bin/env bash
# Vim configuration

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dot_trace 'Configuring Vim ...'

os=$(uname -s)
if [ "$os" = "Linux" ] && command -V apt-get >/dev/null 2>&1; then
  dot_trace 'Installing Vim'
  sudo apt-get install -y -qq build-essential cmake # build helpers
  sudo apt-get install -y -qq python3 python3-dev python3-pip
  sudo apt-get install -y -qq vim neovim python3-pynvim

elif [ "$os" = "Linux" ] && command -V pacman >/dev/null 2>&1; then
  dot_trace 'Installing Vim'
  sudo pacman -S --noconfirm --needed cmake gcc # build helpers
  sudo pacman -S --noconfirm --needed python3 python-pip
  sudo pacman -S --noconfirm --needed vim neovim python3-pynvim

elif [ "$os" = "Darwin" ]; then
  xcode-select -p >/dev/null 2>&1
  if [ $? != 0 ]; then
    dot_trace "Installing XCode command-line tools"
    xcode-select --install
  fi

  dot_trace 'Installing Vim'
  ! brew ls --versions cmake >/dev/null 2>&1 && brew install cmake
  ! brew ls --versions vim >/dev/null 2>&1 && brew install vim --with-override-system-vi --with-lua
  ! brew ls --versions neovim >/dev/null 2>&1 && brew install neovim
  python3 -m pip install --user --upgrade pynvim

else
  dot_error "Unsupported OS: $os"
  return 1 >/dev/null 2>&1
  exit 1
fi

dot_trace "Symlinking Vim configs"
make_symlink "$dotdir/vim/.vim" "$HOME"
make_symlink "$dotdir/vim/.vim/.vimrc" "$HOME"
dot_trace "Symlinking NVim configs"
make_symlink "$dotdir/vim/.vim/.vimrc" "$HOME/.config/nvim" "init.vim"
make_symlink "$dotdir/vim/.vim" "$HOME/.local/share/nvim" "site"

if [ ! -f ~/.vim/autoload/plug.vim ]; then
  dot_trace 'Downloading VimPlug'
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

dot_trace 'Install & configure Vim plugins'
vim +PlugInstall +PlugUpdate +PlugUpgrade +"helptags ~/.vim/doc" +qall
dot_trace 'Install & configure NeoVim plugins'
nvim +PlugInstall +PlugUpdate +PlugUpgrade +"helptags ~/.vim/doc" +qall

dot_trace 'Configuring Vim done.'
