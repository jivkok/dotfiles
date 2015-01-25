#!/bin/bash
# Configuring ZSH

cd $HOME

os=$(uname -s)
if [ "$os" = "Linux" ]; then
    sudo apt-get install zsh
    lnflags=-sb
elif [ "$os" = "Darwin" ]; then
    brew install zsh
    lnflags=-sf
else
    echo "Unsupported OS: $os"
    return
fi

curl -L http://install.ohmyz.sh | sh

[ -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ] && rm -rf ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
mkdir -p ~/.oh-my-zsh/custom/plugins
git clone git://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

ln $lnflags dotfiles/.zprofile .
ln $lnflags dotfiles/.zshrc .
ln $lnflags dotfiles/.zsh-theme .

_zsh=$(which zsh)
[ -z "$(grep $_zsh /etc/shells)" ] && sudo -s "echo $_zsh >> /etc/shells"
chsh -s $_zsh
