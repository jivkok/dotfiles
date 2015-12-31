#!/bin/bash
# Configuring ZSH

os=$(uname -s)
if [ "$os" = "Linux" ]; then
    sudo apt-get install zsh
    _lnflags=-sb
elif [ "$os" = "Darwin" ]; then
    brew install zsh
    _lnflags=-sf
else
    echo "Unsupported OS: $os"
    return
fi

[ -d "$HOME/.oh-my-zsh" ] && rm -rf "$HOME/.oh-my-zsh"
curl -L http://install.ohmyz.sh | sh

mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
git clone https://github.com/zsh-users/zsh-completions "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"
git clone git://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

dotdir="$HOME/dotfiles"
ln $_lnflags "$dotdir/.zprofile" "$HOME/"
ln $_lnflags "$dotdir/.zshrc" "$HOME/"
ln $_lnflags "$dotdir/.zsh-theme" "$HOME/"

_zsh=$(which zsh)
[ -z "$(grep $_zsh /etc/shells)" ] && sudo -s "echo $_zsh >> /etc/shells"
chsh -s $_zsh
unset _lnflags _zsh
