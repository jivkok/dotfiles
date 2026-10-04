#!/usr/bin/env bash
# REQUIRES: git tmux
# COVERS: bin/worktrees.sh sh/setenv.sh
# Tests for bin/worktrees.sh: the git worktree + tmux task helper.
#
# Isolation: a dedicated tmux server (TMUX_TMPDIR, with TMUX/TMUX_PANE
# unset -- see below), a temporary WORKTREES_DIR, and temporary git repos --
# nothing here touches the real $HOME/worktrees, real repos, or the
# developer's running tmux sessions. `claude`, `ranger`, and `lazygit` are
# stubbed on PATH so `new` can be exercised (real tmux panes, real git)
# without depending on -- or actually launching -- those tools.
#
# Real tmux window/pane creation is otherwise expensive and, at volume, has
# crashed a live tmux server (tmux 3.4 segfault under a burst of rapid
# window/split/send-keys calls). So it's used only for scenarios that
# actually assert on tmux behavior (pane layout, window lifecycle, session
# naming); scenarios that only need a task's git/worktree state use
# `make_task` below, which replicates `new`'s git bookkeeping without
# touching tmux at all.
set -uo pipefail

DOTDIR="$(cd "$(dirname "$0")/../.." && pwd)"
WT="$DOTDIR/bin/worktrees.sh"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

# ── Isolation setup ──────────────────────────────────────────────────────────

ROOT_TMP="$(mktemp -d)"
cleanup() {
  tmux kill-server >/dev/null 2>&1 || true
  rm -rf "$ROOT_TMP"
}
trap cleanup EXIT

# `tmux` prefers `$TMUX` (a live session reference) over `$TMUX_TMPDIR` when
# already inside a session -- so if this suite is run from a shell inside a
# real tmux pane, TMUX_TMPDIR alone does NOT isolate it: every `tmux` call
# below would silently target the real, running server instead of this
# throwaway one. Unsetting TMUX (and TMUX_PANE, its per-pane counterpart) is
# what actually makes TMUX_TMPDIR take effect.
unset TMUX TMUX_PANE
export TMUX_TMPDIR="$ROOT_TMP/tmux"
mkdir -p "$TMUX_TMPDIR"
export WORKTREES_DIR="$ROOT_TMP/worktrees"

STUB_BIN="$ROOT_TMP/stubbin"
mkdir -p "$STUB_BIN"
for tool in claude ranger lazygit; do
  write_stub "$STUB_BIN/$tool" "echo \"STUB:$tool \$*\""
done
export PATH="$STUB_BIN:$PATH"

# PATH with everything `new` needs except `ranger` (neither the stub nor any
# real install), to test the missing-dependency path.
NO_RANGER_PATH="$(path_without ranger "$ROOT_TMP")"

# ── Test helpers ─────────────────────────────────────────────────────────────

# make_repo <branch> -- creates a fresh temp git repo with one commit on
# <branch>. Prints its path.
make_repo() {
  local branch="$1" dir
  dir="$(mktemp -d "$ROOT_TMP/repo-XXXXXX")"
  git init -q -b "$branch" "$dir"
  git -C "$dir" config user.name "Test User"
  git -C "$dir" config user.email "test@example.com"
  echo "init" >"$dir/README.md"
  git -C "$dir" add README.md
  git -C "$dir" commit -q -m "initial commit"
  printf '%s' "$dir"
}

# wt_run <repo> <args...> -- runs worktrees.sh from inside <repo>.
# Sets WT_OUT (combined stdout+stderr) and WT_STATUS (exit code).
wt_run() {
  local repo="$1"
  shift
  WT_OUT="$(cd "$repo" && "$WT" "$@" 2>&1)"
  WT_STATUS=$?
}

repo_name() { basename -- "$1"; }

wt_path_for() {
  printf '%s/%s/%s' "$WORKTREES_DIR" "$(repo_name "$1")" "$2"
}

# make_task <repo> <branch> [base] -- creates a task's branch, worktree, and
# recorded base branch directly (the git/worktree bookkeeping `new` does),
# without creating a tmux window. For scenarios that only exercise
# rebase/done/cleanup/list logic and never assert on tmux state -- `new`
# itself is fully covered, tmux window and all, in the "new" and
# "end-to-end lifecycle" sections below. Not itself asserted on, same as
# make_repo: trusted setup plumbing, not the subject under test.
make_task() {
  local repo="$1" branch="$2" base="${3:-master}" path
  path="$(wt_path_for "$repo" "$branch")"
  git -C "$repo" worktree add -q -b "$branch" "$path" "$base"
  git -C "$repo" config "wt.$branch.base" "$base"
}

# wt_is_locked <repo> <worktree-path>
wt_is_locked() { git -C "$1" worktree list --porcelain | awk -v p="$2" '$1=="worktree"{c=substr($0,10)} $1=="locked"&&c==p{f=1} END{exit !f}'; }

tmux_session_exists() { tmux has-session -t "=$1" 2>/dev/null; }
tmux_window_exists() {
  tmux list-windows -t "=$1" -F '#{window_name}' 2>/dev/null | grep -qxF "$2"
}

# wait_pane_contains <pane-target> <substring> -- polls capture-pane briefly.
wait_pane_contains() {
  local target="$1" needle="$2" _n
  for _n in $(seq 1 30); do
    if tmux capture-pane -p -t "$target" 2>/dev/null | grep -qF "$needle"; then
      return 0
    fi
    sleep 0.1
  done
  return 1
}

assert_status() {
  local label="$1" expected="$2" actual="$3"
  if [ "$actual" = "$expected" ]; then
    ok "$label (exit $actual)"
  else
    fail "$label (expected exit $expected, got $actual). Output: $WT_OUT"
  fi
}

# ── General / validation ─────────────────────────────────────────────────────
log_trace "--- general / validation ---"

nongit_dir="$(mktemp -d "$ROOT_TMP/nongit-XXXXXX")"
wt_run "$nongit_dir" list
assert_status "outside a git repo: fails" 1 "$WT_STATUS"
assert_contains "outside a git repo: useful error" "Not inside a Git repository" "$WT_OUT"
repo0="$(make_repo master)"

wt_run "$repo0"
assert_status "no command: fails" 1 "$WT_STATUS"

wt_run "$repo0" bogus-command
assert_status "unknown command: fails" 1 "$WT_STATUS"
assert_contains "unknown command: useful error" "Unknown command" "$WT_OUT"
for cmd in new open rebase "fi" "done" "ri" cleanup; do
  wt_run "$repo0" "$cmd"
  assert_status "'$cmd' without branch arg: fails" 1 "$WT_STATUS"
  assert_contains "'$cmd' without branch arg: usage shown" "Usage:" "$WT_OUT"
done

wt_run "$repo0" new "bad branch!"
assert_status "invalid characters rejected" 1 "$WT_STATUS"

long_branch="$(printf 'a%.0s' $(seq 1 81))"
wt_run "$repo0" new "$long_branch"
assert_status "branch >80 chars rejected" 1 "$WT_STATUS"

wt_run "$repo0" new "bad..name"
assert_status "git-invalid branch name rejected (check-ref-format)" 1 "$WT_STATUS"

wt_run "$repo0" new 123
assert_status "digits-only branch rejected" 1 "$WT_STATUS"
assert_contains "digits-only branch: useful error" "cannot be only digits" "$WT_OUT"

# An unrelated directory at the worktree path is never adopted or overwritten.
collide_path="$(wt_path_for "$repo0" collide-branch)"
mkdir -p "$collide_path"
wt_run "$repo0" new collide-branch
assert_status "unrelated dir at worktree path rejected" 1 "$WT_STATUS"
assert_contains "unrelated dir at worktree path: useful error" "is not a worktree of" "$WT_OUT"
rm -rf "$collide_path"

# A branch checked out somewhere else can't get a second worktree.
wt_run "$repo0" new master
assert_status "branch checked out elsewhere rejected" 1 "$WT_STATUS"
assert_contains "branch checked out elsewhere: useful error" "already checked out" "$WT_OUT"

# ── new ───────────────────────────────────────────────────────────────────────
log_trace "--- new ---"

repo1="$(make_repo master)"
session1="$(repo_name "$repo1")"
branch1="feature/nested/thing"

wt_run "$repo1" new "$branch1"
assert_status "new: succeeds" 0 "$WT_STATUS"

check "new: branch created" git -C "$repo1" show-ref --verify --quiet "refs/heads/$branch1"

wt1="$(wt_path_for "$repo1" "$branch1")"
expected_wt1="$WORKTREES_DIR/$(repo_name "$repo1")/$branch1"
assert_eq "new: worktree path matches WORKTREES_DIR/<repo>/<branch>" "$expected_wt1" "$wt1"
check "new: worktree dir exists (nested '/' path)" test -d "$wt1"

recorded_base="$(git -C "$repo1" config --get "wt.$branch1.base")"
assert_eq "new: records current branch as base" "master" "$recorded_base"

check "new: tmux session created" tmux_session_exists "$session1"
check "new: tmux window created" tmux_window_exists "$session1" "$branch1"

pane_count="$(tmux_pane_count "$session1:$branch1")"
assert_eq "new: window has 4 panes" "4" "$pane_count"

resolved_wt1="$(cd "$wt1" && pwd -P)"
all_cwds_match=1
while IFS= read -r cwd; do
  resolved_cwd="$(cd "$cwd" && pwd -P)"
  [ "$resolved_cwd" = "$resolved_wt1" ] || all_cwds_match=0
done < <(tmux list-panes -t "$session1:$branch1" -F '#{pane_current_path}')
if [ "$all_cwds_match" -eq 1 ]; then
  ok "new: all panes start in the task worktree"
else
  fail "new: not all panes start in the task worktree"
fi

win_width="$(tmux display-message -p -t "$session1:$branch1" '#{window_width}')"
left_width="$(tmux list-panes -t "$session1:$branch1" -F '#{pane_width}' | head -1)"
left_pct=$((left_width * 100 / win_width))
if [ "$left_pct" -ge 55 ] && [ "$left_pct" -le 78 ]; then
  ok "new: left (claude) pane is approximately 67% of window width ($left_pct%)"
else
  fail "new: left pane width ratio out of expected range: $left_pct%"
fi

pane_ids=()
while IFS= read -r pid; do pane_ids+=("$pid"); done < <(tmux list-panes -t "$session1:$branch1" -F '#{pane_id}')

titles="$(tmux list-panes -t "$session1:$branch1" -F '#{pane_title}')"
assert_contains "new: claude pane titled" "claude" "$titles"
assert_contains "new: ranger pane titled" "ranger" "$titles"
assert_contains "new: lazygit pane titled" "lazygit" "$titles"
assert_contains "new: shell pane titled" "shell" "$titles"
check "new: claude launched in left pane with --name <branch>" \
  wait_pane_contains "${pane_ids[0]}" "STUB:claude --name $branch1"
check "new: ranger launched in its pane" \
  wait_pane_contains "${pane_ids[1]}" "STUB:ranger"
check "new: lazygit launched in its pane" \
  wait_pane_contains "${pane_ids[2]}" "STUB:lazygit"

# Second task in the same repo reuses the session, adds a window.
branch1b="feature/second"
wt_run "$repo1" new "$branch1b"
assert_status "new: second task in same repo succeeds" 0 "$WT_STATUS"
session_count="$(tmux list-sessions -F '#{session_name}' | grep -c "^$session1\$")"
assert_eq "new: second task reuses the same tmux session" "1" "$session_count"
check "new: second task gets its own window" tmux_window_exists "$session1" "$branch1b"

# ── new: idempotent re-runs ───────────────────────────────────────────────────
log_trace "--- new: idempotent ---"

wt_run "$repo1" new "$branch1"
assert_status "new: re-run on a complete task succeeds" 0 "$WT_STATUS"
assert_contains "new: re-run reports existing branch" "already exists; reusing it" "$WT_OUT"
assert_contains "new: re-run reports existing worktree" "Worktree already exists" "$WT_OUT"
assert_contains "new: re-run reports existing window" "already exists in session" "$WT_OUT"
assert_eq "new: re-run keeps a single window for the task" "1" \
  "$(tmux list-windows -t "=$session1" -F '#{window_name}' | grep -cxF "$branch1")"
assert_eq "new: re-run leaves the existing window's 4 panes alone" "4" \
  "$(tmux_pane_count "$session1:$branch1")"

# Partial state: window gone (e.g. tmux setup failed) -> re-run recreates only the window.
tmux kill-window -t "=$session1:$branch1"
wt_run "$repo1" new "$branch1"
assert_status "new: re-run after lost window succeeds" 0 "$WT_STATUS"
check "new: re-run recreates the missing window" tmux_window_exists "$session1" "$branch1"
assert_eq "new: recreated window has 4 panes" "4" "$(tmux_pane_count "$session1:$branch1")"

# Partial state: worktree dir deleted by hand -> re-run re-adds it for the existing branch.
rm -rf "$wt1"
wt_run "$repo1" new "$branch1"
assert_status "new: re-run after deleted worktree dir succeeds" 0 "$WT_STATUS"
check "new: re-run re-adds the worktree" test -e "$wt1/.git"
assert_eq "new: re-added worktree is on the task branch" "$branch1" \
  "$(git -C "$wt1" rev-parse --abbrev-ref HEAD)"

# Existing branch without worktree/window (created outside 'new').
git -C "$repo1" branch pre-existing >/dev/null
wt_run "$repo1" new pre-existing
assert_status "new: existing branch is reused" 0 "$WT_STATUS"
check "new: worktree created for existing branch" test -d "$(wt_path_for "$repo1" pre-existing)"
check "new: window created for existing branch" tmux_window_exists "$session1" pre-existing
assert_eq "new: base recorded for existing branch" "master" "$(git -C "$repo1" config --get wt.pre-existing.base)"

# A recorded base is kept, even when re-run from another branch.
git -C "$repo1" config wt.pre-existing.base some-base
wt_run "$repo1" new pre-existing
assert_eq "new: re-run keeps the recorded base" "some-base" "$(git -C "$repo1" config --get wt.pre-existing.base)"

# ── Path resolution ──────────────────────────────────────────────────────────
log_trace "--- path resolution ---"

# WORKTREES_DIR through a symlink: list must still show the task (git reports
# symlink-resolved worktree paths).
repo_link="$(make_repo master)"
mkdir -p "$ROOT_TMP/real-wt"
ln -s "$ROOT_TMP/real-wt" "$ROOT_TMP/link-wt"
WORKTREES_DIR="$ROOT_TMP/link-wt" wt_run "$repo_link" new feature/via-link
assert_status "symlinked WORKTREES_DIR: new succeeds" 0 "$WT_STATUS"
WORKTREES_DIR="$ROOT_TMP/link-wt" wt_run "$repo_link" list
assert_contains "symlinked WORKTREES_DIR: list shows the task" "feature/via-link" "$WT_OUT"

# Relative WORKTREES_DIR, invoked from a subdirectory: one consistent location
# (relative to the current directory) for git and for the script's own checks.
repo_rel="$(make_repo master)"
mkdir -p "$repo_rel/sub"
rel_wt="$(cd "$repo_rel/sub/../.." && pwd -P)/rel-wt/$(repo_name "$repo_rel")/feature/rel"
WT_OUT="$(cd "$repo_rel/sub" && WORKTREES_DIR=../../rel-wt "$WT" new feature/rel 2>&1)"; WT_STATUS=$?
assert_status "relative WORKTREES_DIR: new succeeds" 0 "$WT_STATUS"
check "relative WORKTREES_DIR: worktree created relative to the current dir" test -e "$rel_wt/.git"
WT_OUT="$(cd "$repo_rel/sub" && WORKTREES_DIR=../../rel-wt "$WT" list 2>&1)"
assert_contains "relative WORKTREES_DIR: list shows the task" "feature/rel" "$WT_OUT"

# Submodule: repo root is the submodule's own work tree (not .git/modules).
repo_super="$(make_repo master)"
repo_subsrc="$(make_repo master)"
git -C "$repo_super" -c protocol.file.allow=always submodule add -q "$repo_subsrc" libsub >/dev/null 2>&1
git -C "$repo_super/libsub" config user.name "Test User"
git -C "$repo_super/libsub" config user.email "test@example.com"
wt_run "$repo_super/libsub" new feature/in-sub
assert_status "submodule: new succeeds" 0 "$WT_STATUS"
check "submodule: worktree under WORKTREES_DIR/<submodule>/" test -e "$WORKTREES_DIR/libsub/feature/in-sub/.git"
check "submodule: tmux session named after the submodule" tmux_session_exists libsub
check_not "submodule: no 'modules' session" tmux_session_exists modules

# Missing dependency (ranger): fails cleanly, no partial state.
repo2="$(make_repo master)"
branch2="feature/deps"
WT_OUT="$(cd "$repo2" && PATH="$NO_RANGER_PATH" WORKTREES_DIR="$WORKTREES_DIR" TMUX_TMPDIR="$TMUX_TMPDIR" "$WT" new "$branch2" 2>&1)"
WT_STATUS=$?
assert_status "new: fails when a required tool (ranger) is missing" 1 "$WT_STATUS"
assert_contains "new: missing-dependency error names the tool" "ranger" "$WT_OUT"
check_not "new: no branch created when dependencies are missing" \
  git -C "$repo2" show-ref --verify --quiet "refs/heads/$branch2"
check_not "new: no worktree created when dependencies are missing" \
  test -e "$(wt_path_for "$repo2" "$branch2")"

# ── list ─────────────────────────────────────────────────────────────────────
log_trace "--- list ---"

repo3="$(make_repo master)"
branch3="feature/listed"
wt_run "$repo3" new "$branch3"
assert_status "list: setup task succeeds" 0 "$WT_STATUS"
wt3="$(wt_path_for "$repo3" "$branch3")"

# A second task in repo3 so the session survives when branch3's window is
# killed below (a session is destroyed once its last window closes).
branch3keepalive="feature/keepalive"
wt_run "$repo3" new "$branch3keepalive"
assert_status "list: keepalive task succeeds" 0 "$WT_STATUS"

repo4="$(make_repo master)"
branch4="feature/other-repo"
make_task "$repo4" "$branch4"

wt_run "$repo3" list
assert_status "list: succeeds" 0 "$WT_STATUS"
assert_contains "list: shows this repo's task" "$branch3" "$WT_OUT"
assert_not_contains "list: does not show unrelated repo's task" "$branch4" "$WT_OUT"
assert_contains "list: shows recorded base branch" "master" "$WT_OUT"
assert_contains "list: reports clean git state" "clean" "$WT_OUT"
assert_contains "list: reports running tmux state" "running" "$WT_OUT"
# Dirty state
echo "dirty" >>"$wt3/README.md"
wt_run "$repo3" list
assert_contains "list: reports dirty git state" "dirty" "$WT_OUT"
git -C "$wt3" checkout -q -- README.md

# Ahead count
git -C "$wt3" commit -q --allow-empty -m "task commit"
wt_run "$repo3" list
assert_contains "list: reports commits ahead" "1" "$WT_OUT"
# tmux stopped state
tmux kill-window -t "$(repo_name "$repo3"):$branch3"
wt_run "$repo3" list
assert_contains "list: reports stopped tmux state" "stopped" "$WT_OUT"
# ── open ─────────────────────────────────────────────────────────────────────
log_trace "--- open ---"

wt_run "$repo3" open no-such-branch
assert_status "open: missing worktree fails clearly" 1 "$WT_STATUS"
assert_contains "open: missing worktree error" "No worktree" "$WT_OUT"
# branch3's window was killed above (still has a worktree, no window).
wt_run "$repo3" open "$branch3"
assert_status "open: missing tmux window fails clearly" 1 "$WT_STATUS"
assert_contains "open: missing tmux window error" "No tmux window" "$WT_OUT"
repo5="$(make_repo master)"
branch5="feature/openable"
wt_run "$repo5" new "$branch5"
wt_run "$repo5" open "$branch5"
assert_status "open: succeeds (best-effort outside a terminal)" 0 "$WT_STATUS"

# ── rebase / fi ──────────────────────────────────────────────────────────────
log_trace "--- rebase / fi ---"

repo6="$(make_repo master)"
branch6="feature/rebase-me"
make_task "$repo6" "$branch6"
wt6="$(wt_path_for "$repo6" "$branch6")"

# Advance base, add a non-conflicting commit on the task branch.
echo "base change" >>"$repo6/README.md"
git -C "$repo6" commit -q -am "advance base"
echo "task change" >"$wt6/task.txt"
git -C "$wt6" add task.txt
git -C "$wt6" commit -q -m "task work"

wt_run "$repo6" rebase "$branch6"
assert_status "rebase: succeeds onto advanced base" 0 "$WT_STATUS"
base_head="$(git -C "$repo6" rev-parse master)"
task_parent="$(git -C "$wt6" rev-parse "$branch6~1")"
assert_eq "rebase: task branch now sits on top of base" "$base_head" "$task_parent"

# fi is an alias for rebase.
branch6b="feature/fi-alias"
make_task "$repo6" "$branch6b"
wt6b="$(wt_path_for "$repo6" "$branch6b")"
echo "task change b" >"$wt6b/task-b.txt"
git -C "$wt6b" add task-b.txt
git -C "$wt6b" commit -q -m "task b work"
wt_run "$repo6" "fi" "$branch6b"
assert_status "fi: behaves like rebase" 0 "$WT_STATUS"

# Refuses a dirty task worktree.
echo "uncommitted" >>"$wt6/task.txt"
wt_run "$repo6" rebase "$branch6"
assert_status "rebase: refuses dirty task worktree" 1 "$WT_STATUS"
assert_contains "rebase: dirty worktree error" "uncommitted changes" "$WT_OUT"
git -C "$wt6" checkout -q -- task.txt

# Conflict: stop, leave rebase-conflict state, don't auto-resolve.
repo7="$(make_repo master)"
branch7="feature/conflict"
make_task "$repo7" "$branch7"
wt7="$(wt_path_for "$repo7" "$branch7")"
echo "base version" >"$repo7/conflict.txt"
git -C "$repo7" add conflict.txt
git -C "$repo7" commit -q -m "base edits conflict.txt"
echo "task version" >"$wt7/conflict.txt"
git -C "$wt7" add conflict.txt
git -C "$wt7" commit -q -m "task edits conflict.txt"

wt_run "$repo7" rebase "$branch7"
assert_status "rebase: conflict reports failure" 1 "$WT_STATUS"
assert_contains "rebase: conflict message" "conflict" "$WT_OUT"
check "rebase: leaves worktree in git rebase-conflict state" \
  git -C "$wt7" rev-parse --verify -q REBASE_HEAD
git -C "$wt7" rebase --abort

# ── done / ri ────────────────────────────────────────────────────────────────
log_trace "--- done / ri ---"

repo8="$(make_repo master)"
branch8="feature/done-me"
wt_run "$repo8" new "$branch8"
wt8="$(wt_path_for "$repo8" "$branch8")"
session8="$(repo_name "$repo8")"

# Advance base too, so a real rebase is required before the ff-only merge
# can succeed -- proves `done` rebases before integrating.
echo "base advance" >>"$repo8/README.md"
git -C "$repo8" commit -q -am "advance base for done"
echo "task work" >"$wt8/task.txt"
git -C "$wt8" add task.txt
git -C "$wt8" commit -q -m "task work for done"

wt_run "$repo8" "done" "$branch8"
assert_status "done: succeeds" 0 "$WT_STATUS"
master_head="$(git -C "$repo8" rev-parse master)"
task_head="$(git -C "$wt8" rev-parse "$branch8")"
assert_eq "done: fast-forward merges task into base" "$task_head" "$master_head"
check "done: task worktree preserved" test -d "$wt8"
check "done: task branch preserved" git -C "$repo8" show-ref --verify --quiet "refs/heads/$branch8"
check_not "done: tmux window closed after integration" tmux_window_exists "$session8" "$branch8"

# ri is an alias for done.
repo9="$(make_repo master)"
branch9="feature/ri-alias"
make_task "$repo9" "$branch9"
wt9="$(wt_path_for "$repo9" "$branch9")"
echo "ri work" >"$wt9/ri.txt"
git -C "$wt9" add ri.txt
git -C "$wt9" commit -q -m "ri work"
wt_run "$repo9" "ri" "$branch9"
assert_status "ri: behaves like done" 0 "$WT_STATUS"
assert_eq "ri: fast-forward merges task into base" \
  "$(git -C "$wt9" rev-parse "$branch9")" "$(git -C "$repo9" rev-parse master)"

# Refuses a dirty task worktree.
repo10="$(make_repo master)"
branch10="feature/dirty-task-done"
wt_run "$repo10" new "$branch10"
wt10="$(wt_path_for "$repo10" "$branch10")"
git -C "$wt10" commit -q --allow-empty -m "task commit"
echo "uncommitted" >"$wt10/dirty.txt"
wt_run "$repo10" "done" "$branch10"
assert_status "done: refuses dirty task worktree" 1 "$WT_STATUS"
check "done: tmux window preserved when refused" \
  tmux_window_exists "$(repo_name "$repo10")" "$branch10"
rm -f "$wt10/dirty.txt"

# Refuses a dirty base worktree.
repo11="$(make_repo master)"
branch11="feature/dirty-base-done"
make_task "$repo11" "$branch11"
wt11="$(wt_path_for "$repo11" "$branch11")"
git -C "$wt11" commit -q --allow-empty -m "task commit"
echo "dirty base" >|"$repo11/README.md"
wt_run "$repo11" "done" "$branch11"
assert_status "done: refuses dirty base worktree" 1 "$WT_STATUS"
git -C "$repo11" checkout -q -- README.md

# Conflict: preserves state, does not remove worktree/branch/tmux window.
repo12="$(make_repo master)"
branch12="feature/done-conflict"
wt_run "$repo12" new "$branch12"
wt12="$(wt_path_for "$repo12" "$branch12")"
session12="$(repo_name "$repo12")"
echo "base version" >"$repo12/conflict.txt"
git -C "$repo12" add conflict.txt
git -C "$repo12" commit -q -m "base edits conflict.txt"
echo "task version" >"$wt12/conflict.txt"
git -C "$wt12" add conflict.txt
git -C "$wt12" commit -q -m "task edits conflict.txt"

wt_run "$repo12" "done" "$branch12"
assert_status "done: conflict reports failure" 1 "$WT_STATUS"
check "done: conflict preserves task worktree" test -d "$wt12"
check "done: conflict preserves task branch" \
  git -C "$repo12" show-ref --verify --quiet "refs/heads/$branch12"
check "done: conflict preserves tmux window" tmux_window_exists "$session12" "$branch12"
git -C "$wt12" rebase --abort

# ── cleanup ──────────────────────────────────────────────────────────────────
log_trace "--- cleanup ---"

# Normal cleanup after a completed (`done`) task, nested branch name.
repo13="$(make_repo master)"
branch13="feature/nested/cleanup-me"
make_task "$repo13" "$branch13"
wt13="$(wt_path_for "$repo13" "$branch13")"
git -C "$wt13" commit -q --allow-empty -m "task work"
wt_run "$repo13" "done" "$branch13"
assert_status "cleanup: setup (done) succeeds" 0 "$WT_STATUS"

wt_run "$repo13" cleanup "$branch13"
assert_status "cleanup: succeeds on an integrated task" 0 "$WT_STATUS"
check_not "cleanup: worktree removed" test -e "$wt13"
check_not "cleanup: branch removed" git -C "$repo13" show-ref --verify --quiet "refs/heads/$branch13"
if [ -z "$(git -C "$repo13" config --get "wt.$branch13.base" 2>/dev/null)" ]; then
  ok "cleanup: base-branch metadata removed"
else
  fail "cleanup: base-branch metadata still present"
fi
check_not "cleanup: empty nested parent dirs pruned" \
  test -d "$WORKTREES_DIR/$(repo_name "$repo13")/feature/nested"
check "cleanup: repo boundary dir left in place" \
  test -d "$WORKTREES_DIR/$(repo_name "$repo13")"
check "cleanup: base branch not deleted" \
  git -C "$repo13" show-ref --verify --quiet "refs/heads/master"

# Refuses a dirty worktree without --force.
repo14="$(make_repo master)"
branch14="feature/dirty-cleanup"
make_task "$repo14" "$branch14"
wt14="$(wt_path_for "$repo14" "$branch14")"
echo "uncommitted" >"$wt14/dirty.txt"
wt_run "$repo14" cleanup "$branch14"
assert_status "cleanup: refuses dirty worktree" 1 "$WT_STATUS"
check "cleanup: dirty worktree preserved" test -d "$wt14"

# Refuses an unmerged branch without --force.
repo15="$(make_repo master)"
branch15="feature/unmerged-cleanup"
make_task "$repo15" "$branch15"
wt15="$(wt_path_for "$repo15" "$branch15")"
git -C "$wt15" commit -q --allow-empty -m "unmerged work"
wt_run "$repo15" cleanup "$branch15"
assert_status "cleanup: refuses unmerged branch" 1 "$WT_STATUS"
check "cleanup: unmerged branch preserved" \
  git -C "$repo15" show-ref --verify --quiet "refs/heads/$branch15"

# --force allows discarding dirty/unmerged work.
wt_run "$repo15" cleanup "$branch15" --force
assert_status "cleanup --force: succeeds on unmerged branch" 0 "$WT_STATUS"
check_not "cleanup --force: branch removed" \
  git -C "$repo15" show-ref --verify --quiet "refs/heads/$branch15"
check "cleanup --force: base branch not deleted" \
  git -C "$repo15" show-ref --verify --quiet "refs/heads/master"

# ── Alias ────────────────────────────────────────────────────────────────────
log_trace "--- alias ---"

# sh/setenv.sh sources cleanly on its own (see test-sh-libs.sh), so check the
# alias it actually defines rather than its source text.
mkdir -p "$ROOT_TMP/home"
# shellcheck disable=SC2016  # the snippet expands in the child shell
alias_out="$(env -u SSH_TTY HOME="$ROOT_TMP/home" DOTDIR="$DOTDIR" bash -c \
  'dotdir="$DOTDIR"; source "$dotdir/sh/setenv.sh" >/dev/null 2>&1; alias wt' 2>&1)"
assert_eq "sh/setenv.sh defines the wt alias" "alias wt='$DOTDIR/bin/worktrees.sh'" "$alias_out"

# ── End-to-end lifecycle ─────────────────────────────────────────────────────
# One continuous walkthrough of the full task lifecycle in a single repo:
# new -> list -> rebase (clean, then conflicting) -> resolve -> done -> cleanup.
log_trace "--- end-to-end lifecycle ---"

e2e_repo="$(make_repo master)"
echo "shared" >"$e2e_repo/shared.txt"
git -C "$e2e_repo" add shared.txt
git -C "$e2e_repo" commit -q -m "add shared.txt"
e2e_session="$(repo_name "$e2e_repo")"
e2e_branch="feature/one"

wt_run "$e2e_repo" new "$e2e_branch"
assert_status "e2e: new feature/one succeeds" 0 "$WT_STATUS"
e2e_wt="$(wt_path_for "$e2e_repo" "$e2e_branch")"
check "e2e: branch created" git -C "$e2e_repo" show-ref --verify --quiet "refs/heads/$e2e_branch"
check "e2e: worktree created at expected path" test -d "$e2e_wt"
check "e2e: tmux session/window created" tmux_window_exists "$e2e_session" "$e2e_branch"
check "e2e: new locks the worktree" wt_is_locked "$e2e_repo" "$e2e_wt"
# A missing worktree directory (e.g. repo seen from a container) must not be pruned.
mv "$e2e_wt" "${e2e_wt}.away"
git -C "$e2e_repo" worktree prune
mv "${e2e_wt}.away" "$e2e_wt"
check "e2e: locked worktree survives git worktree prune" wt_is_locked "$e2e_repo" "$e2e_wt"
wt_run "$e2e_repo" new "$e2e_branch"
assert_status "e2e: re-running new on a locked worktree succeeds" 0 "$WT_STATUS"
check "e2e: worktree still locked after re-running new" wt_is_locked "$e2e_repo" "$e2e_wt"
e2e_pane_count="$(tmux_pane_count "$e2e_session:$e2e_branch")"
assert_eq "e2e: window has 4 panes" "4" "$e2e_pane_count"

wt_run "$e2e_repo" list
assert_contains "e2e: list shows the task" "$e2e_branch" "$WT_OUT"
# Commit a change in the task, then advance the base branch (non-conflicting).
echo "task work" >"$e2e_wt/task.txt"
git -C "$e2e_wt" add task.txt
git -C "$e2e_wt" commit -q -m "task work"
echo "base work" >"$e2e_repo/base.txt"
git -C "$e2e_repo" add base.txt
git -C "$e2e_repo" commit -q -m "base work"

wt_run "$e2e_repo" rebase "$e2e_branch"
assert_status "e2e: clean rebase onto advanced base succeeds" 0 "$WT_STATUS"

# Now create a genuine conflict on shared.txt: diverging edits on base and task.
echo "base edit" >|"$e2e_repo/shared.txt"
git -C "$e2e_repo" commit -q -am "base edits shared.txt"
echo "task edit" >|"$e2e_wt/shared.txt"
git -C "$e2e_wt" commit -q -am "task edits shared.txt"

wt_run "$e2e_repo" rebase "$e2e_branch"
assert_status "e2e: conflicting rebase reports failure" 1 "$WT_STATUS"
check "e2e: safe conflict state (REBASE_HEAD present)" \
  git -C "$e2e_wt" rev-parse --verify -q REBASE_HEAD

# Resolve the conflict for real (not just abort) so the task can complete.
echo "merged" >|"$e2e_wt/shared.txt"
git -C "$e2e_wt" add shared.txt
git -C "$e2e_wt" -c core.editor=true rebase --continue >/dev/null

wt_run "$e2e_repo" "done" "$e2e_branch"
assert_status "e2e: done integrates the completed task" 0 "$WT_STATUS"
assert_eq "e2e: base fast-forwarded to task" \
  "$(git -C "$e2e_wt" rev-parse "$e2e_branch")" "$(git -C "$e2e_repo" rev-parse master)"
check_not "e2e: tmux task window removed after done" tmux_window_exists "$e2e_session" "$e2e_branch"
check "e2e: worktree still exists after done" test -d "$e2e_wt"
check "e2e: branch still exists after done" git -C "$e2e_repo" show-ref --verify --quiet "refs/heads/$e2e_branch"

wt_run "$e2e_repo" cleanup "$e2e_branch"
assert_status "e2e: cleanup succeeds" 0 "$WT_STATUS"
check_not "e2e: worktree removed after cleanup" test -e "$e2e_wt"
check_not "e2e: branch removed after cleanup" git -C "$e2e_repo" show-ref --verify --quiet "refs/heads/$e2e_branch"
if [ -z "$(git -C "$e2e_repo" config --get "wt.$e2e_branch.base" 2>/dev/null)" ]; then
  ok "e2e: base-branch metadata removed after cleanup"
else
  fail "e2e: base-branch metadata still present after cleanup"
fi

# A lock placed by hand (not ours) must survive cleanup: removal fails loudly.
log_trace "--- manual lock respected by cleanup ---"
lockrepo="$(make_repo master)"
make_task "$lockrepo" "locked-by-hand"
lockwt="$(wt_path_for "$lockrepo" "locked-by-hand")"
git -C "$lockrepo" worktree lock --reason "mine" "$lockwt"
wt_run "$lockrepo" cleanup "locked-by-hand" --force
check_not "manual lock: cleanup fails" test "$WT_STATUS" -eq 0
check "manual lock: worktree still present" test -d "$lockwt"
check "manual lock: lock retained" wt_is_locked "$lockrepo" "$lockwt"

# ── Summary ──────────────────────────────────────────────────────────────────
finish_test
