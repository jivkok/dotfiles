#!/usr/bin/env bash
set -euo pipefail

fail=0
check_cmd()     { command -v "$1" >/dev/null 2>&1 && echo "  OK  : cmd     $1" || { echo "  FAIL: cmd     $1 not found"; fail=1; }; }
check_file()    { [[ -e "$1" ]]  && echo "  OK  : file    $1" || { echo "  FAIL: file    $1 missing";        fail=1; }; }
check_symlink() { [[ -L "$1" ]]  && echo "  OK  : symlink $1" || { echo "  FAIL: symlink $1 not a symlink";  fail=1; }; }
check_dir()     { [[ -d "$1" ]]  && echo "  OK  : dir     $1" || { echo "  FAIL: dir     $1 missing";        fail=1; }; }
check_git_cfg() { git config --global --get "$1" >/dev/null 2>&1 && echo "  OK  : gitcfg  $1" || { echo "  FAIL: gitcfg  $1 not set"; fail=1; }; }
check_content() { grep -qF "$2" "$1" 2>/dev/null && echo "  OK  : content '$2' in $1" || { echo "  FAIL: content '$2' not in $1"; fail=1; }; }

echo "--- Commands ---"
check_cmd  git
check_cmd  vim
check_cmd  nvim
check_cmd  tmux
check_cmd  zsh
check_cmd  fzf
check_cmd  python3
check_cmd  pipx
check_cmd  starship
check_cmd  eza
check_cmd  rg
check_cmd  jq
check_cmd  curl
check_cmd  wget
check_cmd  shellcheck
check_cmd  tig
check_cmd  uv

echo "--- Shell profiles ---"
check_file    ~/.bash_profile
check_file    ~/.bashrc
check_file    ~/.zshrc
check_content ~/.bashrc  "dotdir"
check_content ~/.zshrc   "dotdir"

echo "--- Misc dotfiles (symlinked into \$HOME) ---"
check_symlink ~/.curlrc
check_symlink ~/.editorconfig
check_symlink ~/.wgetrc

echo "--- Git ---"
check_file    ~/.gitconfig
check_file    ~/.gitignore.global
check_git_cfg user.name
check_git_cfg user.email
check_git_cfg push.default
check_git_cfg core.excludesfile

echo "--- Vim ---"
check_symlink ~/.vim
check_file    ~/.vimrc
check_file    ~/.vim/autoload/plug.vim

echo "--- Tmux ---"
check_symlink ~/.tmux.conf
check_dir     ~/.tmux/plugins/tpm
check_dir     ~/.tmux/plugins/tmux-resurrect
check_dir     ~/.tmux/plugins/tmux-cpu
check_dir     ~/.tmux/plugins/tmux-yank

echo "--- ZSH plugins ---"
check_dir ~/.zsh/plugins/zsh-autosuggestions
check_dir ~/.zsh/plugins/zsh-completions
check_dir ~/.zsh/plugins/zsh-syntax-highlighting

echo "--- FZF ---"
check_file ~/bin/fzf-git.sh

echo "--- Home bin ---"
check_dir ~/bin

echo "--- ZSH shell registration ---"
grep -q "$(command -v zsh)" /etc/shells 2>/dev/null \
  && echo "  OK  : zsh in /etc/shells" \
  || { echo "  FAIL: zsh not in /etc/shells"; fail=1; }

[[ "$fail" -eq 0 ]] || { echo; echo "==> FAILED."; exit 1; }
echo
