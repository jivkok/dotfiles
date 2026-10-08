#!/usr/bin/env bash
# Git worktree + tmux task helper.
#
# Gives each concurrent dev/Claude Code task its own branch, its own Git
# worktree, and its own tmux window (Claude + ranger + lazygit + shell
# panes), so several tasks can be worked on side by side without stepping
# on each other's checkout.
#
# Usage:
#   worktrees.sh new <branch>
#   worktrees.sh list
#   worktrees.sh open <branch>
#   worktrees.sh rebase <branch>   (alias: fi)
#   worktrees.sh done <branch>     (alias: ri)
#   worktrees.sh cleanup <branch> [--force]
#
# WORKTREES_DIR (default: $HOME/worktrees) controls where worktrees are
# created: $WORKTREES_DIR/<repo>/<branch>.
#
# The base branch each task was created from is recorded Git-natively as
# git config key wt.<branch>.base in the repo's local config (not in a
# tracked file), and is used by rebase/done/cleanup instead of assuming
# main/master.

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
source "${DOTFILES_ROOT}/setup/setup_functions.sh"

# abs_physical_path <path>  — absolute path with symlinks resolved, like
# `realpath -m`: a relative path is taken relative to the current directory,
# and components that don't exist yet are appended to the resolved existing
# ancestor. Portable (macOS has no GNU realpath by default).
abs_physical_path() {
  local p="$1" rest=""
  [[ "$p" == "~" ]] && p="$HOME"
  # shellcheck disable=SC2088  # intentional: matching a literal leading "~"
  # in $p's value (e.g. from WORKTREES_DIR="~/worktrees"), not expanding one.
  [[ "$p" == "~/"* ]] && p="$HOME/${p:2}"
  [[ "$p" == /* ]] || p="$PWD/$p"
  # Strip trailing slashes (but keep a bare "/" as-is): otherwise the next
  # line's `${p##*/}` greedily matches through a trailing slash to an empty
  # basename, and the real last component is lost.
  while [[ "$p" == */ && "$p" != "/" ]]; do
    p="${p%/}"
  done
  while [ ! -d "$p" ]; do
    rest="/${p##*/}${rest}"
    p="$(dirname -- "$p")"
  done
  printf '%s%s\n' "$(cd -P -- "$p" && pwd -P)" "$rest"
}

# Canonicalized once, so every path built from it is absolute and matches the
# (symlink-resolved) paths `git worktree list` reports -- whether it was given
# as a relative path, or through a symlinked $HOME / ~/worktrees / macOS /var.
WORKTREES_DIR="$(abs_physical_path "${WORKTREES_DIR:-$HOME/worktrees}")"

# ── Small helpers ────────────────────────────────────────────────────────────

die() {
  log_error "$*"
  exit 1
}

usage() {
  cat <<'EOF'
Usage: worktrees.sh <command> [args]

Commands:
  new <branch>                Create a task branch, worktree, and tmux window (idempotent: completes a partially set-up task)
  list                        List worktrees managed for the current repo
  open <branch>               Attach/switch to a task's tmux window
  rebase <branch>             Rebase a task onto its recorded base branch
  fi <branch>                 Alias for rebase
  done <branch>               Integrate a task into its recorded base branch
  ri <branch>                 Alias for done
  cleanup <branch> [--force]  Remove a completed task's local resources
EOF
}

require_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not inside a Git repository."
}

# Canonical repo root: the main working tree, resolved the same way whether
# invoked from the main checkout or a linked worktree. `git worktree list`
# always lists the main working tree first -- unlike "the parent of the git
# dir", this is also right for submodules (git dir .git/modules/<name>) and
# --separate-git-dir repos.
get_repo_root() {
  git worktree list --porcelain | sed -n '1s/^worktree //p'
}

# Sets the caller's repo_root, repo_name and session for the current repo.
# (Callers declare them `local`; bash's dynamic scoping fills those in.)
load_repo_ctx() {
  require_git_repo
  repo_root="$(get_repo_root)"
  repo_name="$(basename -- "$repo_root")"
  session="$(tmux_session_name "$repo_name")"
}

# Validates <branch> and sets the caller's repo_root, repo_name, session and
# wt_path ($WORKTREES_DIR/<repo>/<branch>).
load_task_ctx() {
  local branch="$1"
  load_repo_ctx
  validate_branch_format "$branch"
  wt_path="$WORKTREES_DIR/$repo_name/$branch"
}

# tmux session names cannot contain '.' or ':' (format-string separators).
tmux_session_name() {
  printf '%s\n' "${1//[.:]/_}"
}

validate_branch_format() {
  local branch="$1"
  [ -n "$branch" ] || die "Branch name is required."
  [ "${#branch}" -le 80 ] || die "Branch name exceeds 80 characters: $branch"
  [[ "$branch" =~ ^[A-Za-z0-9_/-]+$ ]] || die "Branch name contains invalid characters (allowed: a-z A-Z 0-9 - _ /): $branch"
  # The branch is also the tmux window name, and tmux resolves a digits-only
  # window target (session:2) as a window *index* before a name.
  [[ ! "$branch" =~ ^[0-9]+$ ]] || die "Branch name cannot be only digits (it would be read as a tmux window index): $branch"
  git check-ref-format --branch "$branch" >/dev/null 2>&1 || die "Not a valid Git branch name: $branch"
}

check_dependencies() {
  local missing=() cmd
  for cmd in git tmux claude ranger lazygit; do
    _has "$cmd" || missing+=("$cmd")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    # `[*]` joins with IFS's first character; do it in a subshell with IFS
    # set to a plain space, rather than depending on the script's own IFS.
    die "Missing required command(s): $(IFS=' '; printf '%s' "${missing[*]}"). Install them before running 'new'."
  fi
}

branch_exists() {
  local repo_root="$1" branch="$2"
  git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"
}

# ── Base-branch metadata (Git-native: git config, not a tracked file) ────────

set_base_branch() {
  local repo_root="$1" branch="$2" base="$3"
  git -C "$repo_root" config "wt.$branch.base" "$base"
}

get_base_branch() {
  local repo_root="$1" branch="$2"
  git -C "$repo_root" config --get "wt.$branch.base" 2>/dev/null
}

remove_base_branch() {
  local repo_root="$1" branch="$2"
  git -C "$repo_root" config --remove-section "wt.$branch" >/dev/null 2>&1 || true
}

# Resolves and validates a task's recorded base branch, or dies with a clear
# message. Prints the base branch name on stdout -- callers capture this with
# `$(...)`, so die's own message is redirected to stderr here; otherwise it
# would be swallowed into the capture instead of reaching the terminal.
get_base_branch_or_die() {
  local repo_root="$1" branch="$2" base
  base="$(get_base_branch "$repo_root" "$branch")" || true
  [ -n "$base" ] || die "No recorded base branch for '$branch' (it may not have been created with 'new')." >&2
  branch_exists "$repo_root" "$base" || die "Recorded base branch '$base' for '$branch' no longer exists." >&2
  printf '%s\n' "$base"
}

require_worktree_exists() {
  local path="$1" branch="$2"
  [ -d "$path" ] || die "No worktree found for branch '$branch' (expected at $path). Run 'new $branch' first."
}

is_dirty() {
  [ -n "$(git -C "$1" status --porcelain)" ]
}

require_clean_worktree() {
  local path="$1" label="$2"
  ! is_dirty "$path" || die "$label has uncommitted changes: $path"
}

# Prints "<path>\t<branch>" for every worktree of the repo that has a branch
# checked out (parsed from `git worktree list --porcelain`).
worktree_entries() {
  local repo_root="$1" line path="" branch=""
  while IFS= read -r line; do
    case "$line" in
      "worktree "*) path="${line#worktree }" ;;
      "branch "*) branch="${line#branch refs/heads/}" ;;
      "")
        if [ -n "$path" ] && [ -n "$branch" ]; then printf '%s\t%s\n' "$path" "$branch"; fi
        path=""
        branch=""
        ;;
    esac
  done < <(git -C "$repo_root" worktree list --porcelain; printf '\n')
}

# Prints the path of the linked (or main) worktree that currently has
# <branch> checked out, or nothing (exit 1) if none does.
find_worktree_for_branch() {
  local repo_root="$1" branch="$2" path b
  while IFS=$'\t' read -r path b; do
    if [ "$b" = "$branch" ]; then
      printf '%s\n' "$path"
      return 0
    fi
  done < <(worktree_entries "$repo_root")
  return 1
}

# Task worktrees live outside the repo, so a container or VM that sees only
# the repo (e.g. claude-code-docker.sh without `worktrees: true`) finds their
# directories missing and `git worktree prune` would drop their metadata. A
# lock makes prune/gc skip them; `new` locks, `cleanup` unlocks first.
#
# is_worktree_locked <repo_root> <path> [reason] -- with a reason, true only
# for a lock carrying exactly that reason (i.e. one we placed).
is_worktree_locked() {
  local repo_root="$1" path="$2" want="${3:-}"
  git -C "$repo_root" worktree list --porcelain \
    | awk -v p="$path" -v w="$want" '
        $1 == "worktree" { cur = substr($0, 10) }
        $1 == "locked" && cur == p { if (w == "" || substr($0, 8) == w) found = 1 }
        END { exit !found }'
}

# Our lock's reason embeds the worktree's own path, not just a generic
# phrase, so a lock placed by hand would have to coincidentally reuse this
# exact path-specific string (not just a guessable constant) to be mistaken
# for ours.
_wt_lock_reason() {
  printf 'managed by worktrees.sh: %s' "$1"
}

# Idempotent: a no-op when the worktree is already locked.
lock_worktree() {
  local repo_root="$1" path="$2"
  is_worktree_locked "$repo_root" "$path" && return 0
  git -C "$repo_root" worktree lock --reason "$(_wt_lock_reason "$path")" -- "$path"
}

# Idempotent: a no-op unless the worktree carries our lock -- a lock placed by
# hand (different reason) is left alone, so removing it still fails loudly.
unlock_worktree() {
  local repo_root="$1" path="$2"
  is_worktree_locked "$repo_root" "$path" "$(_wt_lock_reason "$path")" || return 0
  git -C "$repo_root" worktree unlock -- "$path"
}

# Removes now-empty directories from $dir upward, stopping once $boundary
# itself would be reached (the boundary, e.g. $WORKTREES_DIR/<repo>, is
# always left in place even if empty).
prune_empty_parent_dirs() {
  local dir="$1" boundary="$2"
  while [[ "$dir" == "$boundary"/* ]]; do
    rmdir -- "$dir" 2>/dev/null || break
    dir="$(dirname -- "$dir")"
  done
}

# ── tmux workspace ────────────────────────────────────────────────────────────

tmux_window_exists() {
  local session="$1" window="$2"
  tmux list-windows -t "=$session" -F '#{window_name}' 2>/dev/null | grep -qxF "$window"
}

# Closes the window, stopping every pane's process. If this script is running
# in one of those panes, killing the window now would SIGHUP it mid-command:
# stop the other panes now and close the window once the script exits
# successfully (on failure this pane stays, with the error on screen).
close_tmux_window_if_exists() {
  local session="$1" window="$2"
  tmux_window_exists "$session" "$window" || return 0
  if [ -n "${TMUX_PANE:-}" ] \
    && tmux list-panes -t "=$session:$window" -F '#{pane_id}' | grep -qxF "$TMUX_PANE"; then
    tmux kill-pane -a -t "$TMUX_PANE"
    DEFERRED_WINDOW="=$session:$window"
    trap close_deferred_window EXIT
    log_info "Closing tmux window '$window' in session '$session' on exit."
    return 0
  fi
  tmux kill-window -t "=$session:$window"
  log_info "Closed tmux window '$window' in session '$session'."
}

# EXIT trap set by close_tmux_window_if_exists.
close_deferred_window() {
  local rc=$?
  [ "$rc" -ne 0 ] || tmux kill-window -t "$DEFERRED_WINDOW"
}

# split_pane <-h|-v> <target-pane> <percent> <dir>  — split <percent> of the
# target pane's width (-h) or height (-v) off into a new pane starting in
# <dir>; prints the new pane's id.
#
# Uses `-l <computed-cells>` (queried from the actual current pane size)
# rather than `-p <percent>`: `-p` requires a client to have attached to the
# session at least once, and fails with "size missing" otherwise -- always
# true right after `new-session`/`new-window` for a brand-new task.
split_pane() {
  local direction="$1" target="$2" pct="$3" dir="$4" dimension=height size
  [ "$direction" = "-h" ] && dimension=width
  size="$(tmux display-message -p -t "$target" "#{pane_${dimension}}")"
  size=$((size * pct / 100))
  [ "$size" -ge 1 ] || size=1
  tmux split-window "$direction" -l "$size" -P -F '#{pane_id}' -t "$target" -c "$dir"
}

# Creates the task's tmux window: one session per repo, one window per task,
# with a 67/33 left/right split and ranger/lazygit/shell stacked on the
# right. All panes start in the task worktree.
#
# Panes are targeted by pane-id (%N, from `-P -F '#{pane_id}'`) rather than
# by index (.0/.1/...): a user tmux.conf may set pane-base-index to 1, which
# would make `.0` targets fail.
create_tmux_task_window() {
  local session="$1" branch="$2" worktree_path="$3"
  local pane0 pane1 pane2 pane3 claude_cmd

  if tmux has-session -t "=$session" 2>/dev/null; then
    pane0="$(tmux new-window -P -F '#{pane_id}' -t "${session}:" -n "$branch" -c "$worktree_path")"
  else
    pane0="$(tmux new-session -d -P -F '#{pane_id}' -s "$session" -n "$branch" -c "$worktree_path")"
  fi

  pane1="$(split_pane -h "$pane0" 33 "$worktree_path")"
  pane2="$(split_pane -v "$pane1" 67 "$worktree_path")"
  pane3="$(split_pane -v "$pane2" 50 "$worktree_path")"

  # Pane titles are the task layout's labels; stop each pane's shell prompt
  # (title escape sequences) from overwriting them.
  local p
  for p in "$pane0" "$pane1" "$pane2" "$pane3"; do
    tmux set-option -p -t "$p" allow-set-title off 2>/dev/null || true
  done

  tmux select-pane -t "$pane0" -T "claude" 2>/dev/null || true
  tmux select-pane -t "$pane1" -T "ranger" 2>/dev/null || true
  tmux select-pane -t "$pane2" -T "lazygit" 2>/dev/null || true
  tmux select-pane -t "$pane3" -T "shell" 2>/dev/null || true

  claude_cmd="$(printf 'claude --name %q' "$branch")"
  tmux send-keys -t "$pane0" "$claude_cmd" Enter
  tmux send-keys -t "$pane1" "ranger" Enter
  tmux send-keys -t "$pane2" "lazygit" Enter

  tmux select-pane -t "$pane0"
}

# Attaches (outside tmux) or switches (inside tmux) to a task's window.
# Best-effort outside a real terminal: never blocks/hangs, just reports.
attach_or_switch() {
  local session="$1" window="$2"
  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "${session}:${window}"
  elif [ -t 0 ] && [ -t 1 ]; then
    tmux attach-session -t "${session}:${window}"
  else
    log_warning "Not attached to a terminal; skipping auto-attach. Run 'open $window' to attach."
  fi
}

# ── Commands ──────────────────────────────────────────────────────────────────

# Idempotent: each step (branch, base record, worktree, tmux session, tmux
# window) is skipped when it already exists, so re-running 'new' after a
# partial failure completes the task setup instead of erroring out.
cmd_new() {
  local branch="$1"
  local repo_root repo_name session wt_path base current checked_out_at
  load_task_ctx "$branch"
  check_dependencies

  current="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  [ "$current" != "HEAD" ] || current=""

  # Forget worktrees whose directories were deleted by hand, so they can be
  # re-added. Ours are locked (see lock_worktree), which prune skips, so
  # unlock this task's own if its directory is gone; other tasks' stay put.
  [ -d "$wt_path" ] || unlock_worktree "$repo_root" "$wt_path"
  git -C "$repo_root" worktree prune

  # Base branch record (kept if already recorded)
  base="$(get_base_branch "$repo_root" "$branch")" || true
  if [ -z "$base" ]; then
    [ -n "$current" ] || die "Could not determine the current branch (detached HEAD?); check out a branch first."
    base="$current"
  fi

  # Branch + worktree
  checked_out_at="$(find_worktree_for_branch "$repo_root" "$branch")" || true
  if [ -n "$checked_out_at" ]; then
    [ "$(abs_physical_path "$checked_out_at")" = "$wt_path" ] \
      || die "Branch '$branch' is already checked out at $checked_out_at (expected $wt_path)."
    log_info "Branch '$branch' already exists; reusing it."
    log_info "Worktree already exists: $wt_path"
  else
    [ ! -e "$wt_path" ] || die "Worktree path already exists but is not a worktree of '$branch': $wt_path"
    mkdir -p -- "$(dirname -- "$wt_path")"
    if branch_exists "$repo_root" "$branch"; then
      log_info "Branch '$branch' already exists; reusing it."
      log_info "Creating worktree for existing branch '$branch' ..."
      git -C "$repo_root" worktree add "$wt_path" "$branch"
    else
      log_info "Creating branch '$branch' from '$base' ..."
      git -C "$repo_root" worktree add -b "$branch" "$wt_path" "$base"
    fi
  fi
  set_base_branch "$repo_root" "$branch" "$base"
  lock_worktree "$repo_root" "$wt_path"

  # tmux session + window (create_tmux_task_window reuses an existing session)
  if tmux_window_exists "$session" "$branch"; then
    log_info "tmux window '$branch' already exists in session '$session'."
  else
    log_info "Creating tmux window '$branch' in session '$session' ..."
    create_tmux_task_window "$session" "$branch" "$wt_path"
  fi

  attach_or_switch "$session" "$branch" || log_warning "Could not attach/switch to the task window; run 'open $branch' to attach."
}

cmd_list() {
  local repo_root repo_name session base_dir windows path branch key value
  load_repo_ctx
  base_dir="$WORKTREES_DIR/$repo_name"

  # Fetched once, not per task: open windows and recorded base branches.
  windows=$'\n'"$(tmux list-windows -t "=$session" -F '#{window_name}' 2>/dev/null || true)"$'\n'
  local -A bases=()
  while IFS=' ' read -r key value; do
    key="${key#wt.}"
    bases[${key%.base}]="$value"
  done < <(git -C "$repo_root" config --get-regexp '^wt\..*\.base$' 2>/dev/null || true)

  printf '%-24s %-10s %-10s %-8s %s\n' "BRANCH" "BASE" "TMUX" "GIT" "AHEAD"

  while IFS=$'\t' read -r path branch; do
    [[ "$path" == "$base_dir"/* ]] || continue
    local base="${bases[$branch]:--}" tmux_state=stopped git_state=clean ahead="-"
    [[ "$windows" == *$'\n'"$branch"$'\n'* ]] && tmux_state="running"
    is_dirty "$path" && git_state="dirty"
    if [ "$base" != "-" ] && branch_exists "$repo_root" "$base"; then
      ahead="$(git -C "$repo_root" rev-list --count "$base..$branch" 2>/dev/null || printf '?')"
    fi
    printf '%-24s %-10s %-10s %-8s %s\n' "$branch" "$base" "$tmux_state" "$git_state" "$ahead"
  done < <(worktree_entries "$repo_root")
}

cmd_open() {
  local branch="$1" repo_root repo_name session wt_path
  load_task_ctx "$branch"

  require_worktree_exists "$wt_path" "$branch"
  tmux has-session -t "=$session" 2>/dev/null || die "No tmux session for repo '$repo_name'."
  tmux_window_exists "$session" "$branch" || die "No tmux window for task '$branch'."

  attach_or_switch "$session" "$branch"
}

cmd_rebase() {
  local branch="$1" repo_root repo_name session wt_path base
  load_task_ctx "$branch"

  require_worktree_exists "$wt_path" "$branch"
  base="$(get_base_branch_or_die "$repo_root" "$branch")"
  require_clean_worktree "$wt_path" "Task worktree for '$branch'"

  log_info "Rebasing '$branch' onto '$base' ..."
  if git -C "$wt_path" rebase "$base"; then
    log_info "Rebase of '$branch' onto '$base' complete."
  else
    log_error "Rebase conflict while rebasing '$branch' onto '$base'."
    log_error "Resolve conflicts in $wt_path, then run: git -C \"$wt_path\" rebase --continue"
    log_error "(or: git -C \"$wt_path\" rebase --abort to cancel)"
    exit 1
  fi
}

cmd_done() {
  local branch="$1" repo_root repo_name session wt_path base base_wt
  load_task_ctx "$branch"

  require_worktree_exists "$wt_path" "$branch"
  require_clean_worktree "$wt_path" "Task worktree for '$branch'"
  base="$(get_base_branch_or_die "$repo_root" "$branch")"

  base_wt="$(find_worktree_for_branch "$repo_root" "$base")" || true
  [ -n "$base_wt" ] || die "Base branch '$base' is not checked out in any worktree; check it out before running 'done'."
  require_clean_worktree "$base_wt" "Base branch worktree ('$base')"

  log_info "Rebasing '$branch' onto '$base' before integration ..."
  if ! git -C "$wt_path" rebase "$base"; then
    log_error "Rebase conflict while rebasing '$branch' onto '$base'; integration aborted."
    log_error "Resolve conflicts in $wt_path, then re-run 'done $branch'."
    exit 1
  fi

  log_info "Fast-forward merging '$branch' into '$base' ..."
  if ! git -C "$base_wt" merge --ff-only "$branch"; then
    log_error "Fast-forward merge of '$branch' into '$base' failed; task worktree and branch are preserved."
    exit 1
  fi

  close_tmux_window_if_exists "$session" "$branch"

  log_info "Integrated '$branch' into '$base'. Worktree/branch preserved; run 'cleanup $branch' when ready."
  # TODO: support creating/pushing a pull request instead of a direct local merge.
}

cmd_cleanup() {
  local branch="$1" force="$2" repo_root repo_name session wt_path
  local base dirty ahead unmerged=0 base_exists=0 verify_failed=0
  load_task_ctx "$branch"

  require_worktree_exists "$wt_path" "$branch"

  dirty="$(git -C "$wt_path" status --porcelain)"
  base="$(get_base_branch "$repo_root" "$branch")" || true

  if [ -n "$base" ] && branch_exists "$repo_root" "$base"; then
    base_exists=1
    if ahead="$(git -C "$repo_root" rev-list --count "$base..$branch" 2>/dev/null)"; then
      [ "$ahead" -gt 0 ] && unmerged=1
    else
      # rev-list failed: merged status is unknown, not "0 commits ahead" --
      # treat it like the no-valid-base case below (refuse without --force).
      unmerged=1
      verify_failed=1
    fi
  else
    unmerged=1
  fi

  if [ "$force" != "1" ]; then
    [ -z "$dirty" ] || die "Worktree for '$branch' has uncommitted changes. Commit/stash them, or re-run with --force to discard."
    if [ "$unmerged" -eq 1 ]; then
      if [ "$verify_failed" -eq 1 ]; then
        die "Could not verify '$branch' is fully merged ('git rev-list' failed). Re-run with --force to discard."
      elif [ "$base_exists" -eq 1 ]; then
        die "Branch '$branch' has commits not yet integrated into '$base'. Run 'done $branch' first, or re-run with --force to discard."
      else
        die "Could not verify '$branch' is fully merged (no recorded/valid base branch). Re-run with --force to discard."
      fi
    fi
  elif [ -n "$dirty" ] || [ "$unmerged" -eq 1 ]; then
    log_warning "--force: discarding task '$branch' (uncommitted-changes=$([ -n "$dirty" ] && echo yes || echo no), unmerged=$([ "$unmerged" -eq 1 ] && echo yes || echo no))."
  fi

  log_info "Removing worktree $wt_path ..."
  local remove_args=()
  [ "$force" = "1" ] && remove_args=(--force)
  # A locked worktree can't be removed (even with --force), so unlock first,
  # and restore the lock if the removal fails and the worktree stays.
  unlock_worktree "$repo_root" "$wt_path"
  if ! git -C "$repo_root" worktree remove "${remove_args[@]+"${remove_args[@]}"}" -- "$wt_path"; then
    lock_worktree "$repo_root" "$wt_path"
    die "Could not remove worktree $wt_path."
  fi

  # Only close the tmux window once the worktree is actually gone -- closing
  # it first would destroy the task's panes even on a failed removal above,
  # which leaves the worktree/branch (correctly) in place.
  close_tmux_window_if_exists "$session" "$branch"

  # -D (not -d): our own base-relative merge check above already gates this;
  # git's built-in -d safety check compares against the current HEAD of the
  # invoking repo, which is not necessarily the recorded base branch.
  git -C "$repo_root" branch -D "$branch"
  remove_base_branch "$repo_root" "$branch"
  prune_empty_parent_dirs "$(dirname -- "$wt_path")" "$WORKTREES_DIR/$repo_name"

  log_info "Cleaned up task '$branch'."
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

main() {
  [ "$#" -ge 1 ] || { usage >&2; exit 1; }
  local cmd="$1"
  shift

  case "$cmd" in
    new | open | rebase | fi | done | ri | cleanup)
      [ "$#" -ge 1 ] || die "Usage: worktrees.sh $cmd <branch>$([ "$cmd" = cleanup ] && echo ' [--force]')"
      ;;
  esac

  case "$cmd" in
    new) cmd_new "$1" ;;
    list) cmd_list ;;
    open) cmd_open "$1" ;;
    rebase | fi) cmd_rebase "$1" ;;
    done | ri) cmd_done "$1" ;;
    cleanup)
      local force=0
      [ "${2:-}" = "--force" ] && force=1
      cmd_cleanup "$1" "$force"
      ;;
    -h | --help | help) usage ;;
    *)
      usage >&2
      die "Unknown command: $cmd"
      ;;
  esac
}

main "$@"
