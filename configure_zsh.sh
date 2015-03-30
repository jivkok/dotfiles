#!/bin/bash
# Configuring ZSH

cd $HOME

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

[ -d ~/.oh-my-zsh ] && rm -rf ~/.oh-my-zsh
curl -L http://install.ohmyz.sh | sh

mkdir -p ~/.oh-my-zsh/custom/plugins
git clone git://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

ln $_lnflags dotfiles/.zprofile .
ln $_lnflags dotfiles/.zshrc .
ln $_lnflags dotfiles/.zsh-theme .

_zsh=$(which zsh)
[ -z "$(grep $_zsh /etc/shells)" ] && sudo -s "echo $_zsh >> /etc/shells"
chsh -s $_zsh
unset _lnflags _zsh

