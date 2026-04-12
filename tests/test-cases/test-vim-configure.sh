#!/usr/bin/env bash
# REQUIRES: vim
set -euo pipefail

DOTDIR="$(cd "$(dirname "$0")/../.." && pwd)"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

# ── Binaries ──────────────────────────────────────────────────────────────────
log_trace "--- configure_vim.sh: binaries ---"

assert_cmd vim
assert_cmd nvim

# ── Symlinks ──────────────────────────────────────────────────────────────────
log_trace "--- configure_vim.sh: config symlinks ---"

assert_vim_symlink() {
  local link="$1" expected_target="$2"
  local actual_target
  actual_target=$(readlink "$link" 2>/dev/null || true)
  if [ "$actual_target" = "$expected_target" ]; then
    ok "symlink ${link##"$HOME/"} → $expected_target"
  else
    fail "symlink ${link##"$HOME/"}: expected → $expected_target, got → $actual_target"
  fi
}

assert_vim_symlink "$HOME/.vim"                    "$DOTDIR/vim/.vim"
assert_vim_symlink "$HOME/.vimrc"                  "$DOTDIR/vim/.vim/.vimrc"
assert_vim_symlink "$HOME/.config/nvim/init.vim"   "$DOTDIR/vim/.vim/.vimrc"
assert_vim_symlink "$HOME/.local/share/nvim/site"  "$DOTDIR/vim/.vim"

# ── vim-plug ──────────────────────────────────────────────────────────────────
log_trace "--- configure_vim.sh: vim-plug ---"

assert_file_exists "$HOME/.vim/autoload/plug.vim"

# ── Plugin directories ────────────────────────────────────────────────────────
log_trace "--- configure_vim.sh: plugins ---"

assert_dir "$HOME/.vim/plugins/ale"
assert_dir "$HOME/.vim/plugins/fzf.vim"
assert_dir "$HOME/.vim/plugins/indentLine"
assert_dir "$HOME/.vim/plugins/nerdtree"
assert_dir "$HOME/.vim/plugins/undotree"
assert_dir "$HOME/.vim/plugins/vim-fugitive"
assert_dir "$HOME/.vim/plugins/vim-gitgutter"
assert_dir "$HOME/.vim/plugins/vim-surround"
assert_dir "$HOME/.vim/plugins/vim-visual-multi"
assert_dir "$HOME/.vim/plugins/vista.vim"

# ── Summary ───────────────────────────────────────────────────────────────────
finish_test
