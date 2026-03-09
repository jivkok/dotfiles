#!/usr/bin/env bash
set -euo pipefail

# ${BASH_SOURCE[0]} is bash-only; fall back to $0 when run via zsh.
# shellcheck source=../../testlib.sh
source "$(dirname "${BASH_SOURCE[0]:-$0}")/../../testlib.sh"

check_cmd()     { command -v "$1" >/dev/null 2>&1 && ok "cmd     $1" || fail "cmd     $1 not found"; }
check_file()    { [ -e "$1" ]  && ok "file    $1" || fail "file    $1 missing"; }
check_symlink() { [ -L "$1" ]  && ok "symlink $1" || fail "symlink $1 not a symlink"; }
check_dir()     { [ -d "$1" ]  && ok "dir     $1" || fail "dir     $1 missing"; }
check_git_cfg() { git config --global --get "$1" >/dev/null 2>&1 && ok "gitcfg  $1" || fail "gitcfg  $1 not set"; }
check_content() { grep -qF "$2" "$1" 2>/dev/null && ok "content '$2' in $1" || fail "content '$2' not in $1"; }

log_trace "--- Commands ---"
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

log_trace "---Shell profiles ---"
check_file    ~/.bash_profile
check_file    ~/.bashrc
check_file    ~/.zshrc
check_content ~/.bashrc  "dotdir"
check_content ~/.zshrc   "dotdir"

log_trace "---Misc dotfiles (symlinked into \$HOME) ---"
check_symlink ~/.curlrc
check_symlink ~/.editorconfig
check_symlink ~/.wgetrc

log_trace "---Git ---"
check_file    ~/.gitconfig
check_file    ~/.gitignore.global
check_git_cfg user.name
check_git_cfg user.email
check_git_cfg push.default
check_git_cfg core.excludesfile

log_trace "---Vim ---"
check_symlink ~/.vim
check_file    ~/.vimrc
check_file    ~/.vim/autoload/plug.vim

log_trace "---Tmux ---"
check_symlink ~/.tmux.conf
check_dir     ~/.tmux/plugins/tpm
check_dir     ~/.tmux/plugins/tmux-resurrect
check_dir     ~/.tmux/plugins/tmux-cpu
check_dir     ~/.tmux/plugins/tmux-yank

log_trace "---ZSH plugins ---"
check_dir ~/.zsh/plugins/zsh-autosuggestions
check_dir ~/.zsh/plugins/zsh-completions
check_dir ~/.zsh/plugins/zsh-syntax-highlighting

log_trace "---FZF ---"
check_file ~/bin/fzf-git.sh

log_trace "---Home bin ---"
check_dir ~/bin

log_trace "---ZSH shell registration ---"
grep -q "$(command -v zsh)" /etc/shells 2>/dev/null \
  && ok "zsh in /etc/shells" \
  || fail "zsh not in /etc/shells"

[ "${_TEST_FAIL}" -eq 0 ] || { log_error "==> FAILED."; exit 1; }
log_trace ""
