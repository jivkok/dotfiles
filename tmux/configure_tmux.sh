#!/usr/bin/env bash
# Tmux configuration

dotdir="$( cd "$( dirname "$0" )/.." && pwd )"
source "$dotdir/setup/setup_functions.sh"

dot_trace 'Configuring Tmux ...'

os=$(uname -s)
if [ "$os" = "Linux" ] && command -V apt >/dev/null 2>&1; then
    sudo apt-get install -y tmux

elif [ "$os" = "Linux" ] && command -V pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm tmux

elif [ "$os" = "Darwin" ]; then
    ! brew ls --versions tmux >/dev/null 2>&1 && brew install tmux

else
    dot_trace "Unsupported OS: $os"
    return 1 >/dev/null 2>&1
    exit 1
fi

# Config
make_symlink "$dotdir/tmux/.tmux.conf" "$HOME"

# Plugins
_tmux_plugins_dir="$HOME/.tmux/plugins"
dot_trace "Install & configure Tmux plugins into $_tmux_plugins_dir"
mkdir -p "$_tmux_plugins_dir"
for _plugin in {tpm,tmux-cpu,tmux-resurrect,tmux-yank}; do
    dot_trace "Tmux plugin: $_plugin"
    if [ -d "$_tmux_plugins_dir/$_plugin" ]; then
        git -C "$_tmux_plugins_dir/$_plugin" pull --prune
    else
        git clone "https://github.com/tmux-plugins/$_plugin" "$_tmux_plugins_dir/$_plugin"
    fi
done;

dot_trace 'Configuring Tmux done.'
