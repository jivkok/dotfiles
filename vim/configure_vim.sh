#!/usr/bin/env bash
# Vim configuration

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

log_info 'Configuring Vim/NeoVim ...'

if $_is_debian; then
  log_trace 'Installing Vim/NeoVim'
  install_or_upgrade_apt_package python3
  install_or_upgrade_apt_package python3-dev
  install_or_upgrade_apt_package python3-pip
  install_or_upgrade_apt_package vim
  install_or_upgrade_apt_package neovim
  install_or_upgrade_apt_package python3-pynvim

elif $_is_arch; then
  log_trace 'Installing Vim/NeoVim'
  install_or_upgrade_pacman_package python3
  install_or_upgrade_pacman_package python-pip
  install_or_upgrade_pacman_package vim
  install_or_upgrade_pacman_package neovim
  install_or_upgrade_pacman_package python-pynvim

elif $_is_osx; then
  if ! xcode-select -p >/dev/null 2>&1; then
    log_trace "Installing XCode command-line tools"
    xcode-select --install
  fi

  log_trace 'Installing Vim/NeoVim'
  install_or_upgrade_brew_package vim
  install_or_upgrade_brew_package neovim
  python3.12 -m pip install --break-system-packages --upgrade pynvim >/dev/null

else
  log_error "Unsupported OS: ${_OS}"
  exit 1
fi

log_trace "Symlinking Vim configs"
make_symlink "$dotdir/vim/.vim" "$HOME"
make_symlink "$dotdir/vim/.vim/.vimrc" "$HOME"
log_trace "Symlinking NVim configs"
make_symlink "$dotdir/vim/.vim/.vimrc" "$HOME/.config/nvim" "init.vim"
make_symlink "$dotdir/vim/.vim" "$HOME/.local/share/nvim" "site"

if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  log_trace 'Downloading VimPlug'
  mkdir -p "$HOME/.vim/autoload"
  download_file "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" "$HOME/.vim/autoload/plug.vim"
fi

if _has vim; then
  log_trace 'Install & configure Vim plugins'
  vim +PlugUpgrade +PlugInstall +PlugUpdate +"helptags ~/.vim/doc" +qall
else
  log_warning 'vim not found in PATH, skipping plugin install'
fi
if _has nvim; then
  log_trace 'Install & configure NeoVim plugins'
  nvim +PlugUpgrade +PlugInstall +PlugUpdate +"helptags ~/.vim/doc" +qall
else
  log_warning 'nvim not found in PATH, skipping plugin install'
fi

log_info 'Configuring Vim/NeoVim done.'
