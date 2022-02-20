#!/usr/bin/env bash
# Configure ZSH

dotdir="$( cd "$( dirname "$0" )" && pwd )"
source "$dotdir/setupfunctions.sh"

dot_trace "Configuring ZSH ..."

os=$(uname -s)
if [ "$os" = "Linux" ]; then
    if ! dpkg -s zsh >/dev/null 2>&1 ; then
        dot_trace "Installing ZSH ..."
        sudo apt-get install -y zsh
        dot_trace "Installing ZSH done."
    fi
elif [ "$os" = "Darwin" ]; then
    if ! brew ls --versions zsh >/dev/null 2>&1 ; then
        dot_trace "Installing ZSH ..."
        brew install zsh
        dot_trace "Installing ZSH done."
    fi
elif [[ "$os" == CYGWIN* ]]; then
    if command -v pact >/dev/null 2>&1 ; then # Babun
        dot_trace "Cygwin/Babun has ZSH pre-installed"
    else
        dot_error "No automatic ZSH install in Cygwin"
        return
    fi
else
    dot_error "Unsupported OS: $os"
    return
fi

if [ -d "$HOME/.oh-my-zsh" ]; then
    dot_trace "Updating oh-my-zsh ..."
    git -C "$HOME/.oh-my-zsh" pull --rebase --stat origin master

    for dir in $(find "$HOME/.oh-my-zsh/custom/plugins" -mindepth 1 -maxdepth 1 -type d); do
        [ -d "$dir/.git" ] && dot_trace "Updating $dir" && git -C "$dir" pull --prune
    done
    dot_trace "Updating oh-my-zsh done."
else
    dot_trace "Installing oh-my-zsh ..."
    # https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh
    git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh "$HOME/.oh-my-zsh"

    mkdir -p "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    git clone https://github.com/supercrabtree/k "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/k"
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-completions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    dot_trace "Installing oh-my-zsh done."
fi

_zsh=$(command -v zsh)

if [ -z "$(grep "$_zsh" /etc/shells)" ] ; then
    dot_trace "Adding ZSH as supported shell"
    echo "$_zsh" | sudo tee -a /etc/shells
else
    dot_trace "Check: ZSH is supported shell"
fi

if [ "$SHELL" != "$_zsh" ]; then
    dot_trace "Switching to ZSH as default shell"
    [ -f /etc/pam.d/chsh ] && sudo sed -ir 's/^\(auth\)\s\+\(required\)\s\+\(pam_shells\.so\)/\1 sufficient \3/' /etc/pam.d/chsh
    chsh -s "$_zsh"
else
    dot_trace "Check: ZSH is default shell"
fi

unset _zsh

dot_trace "Configuring ZSH done."
