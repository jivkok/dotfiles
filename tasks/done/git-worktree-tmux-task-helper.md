# Task: Add Git Worktree + tmux Task Helper

**Status**: done
**Priority**: medium
**Created**: 2026-09-20

## Description

Add a lightweight helper for managing concurrent development tasks using Git worktrees and tmux.

The goal is to support a workflow where each development/Claude Code task has:

* its own Git branch;
* its own Git worktree;
* its own tmux window;
* its own Claude Code session;
* supporting shell, ranger, and lazygit panes.

The implementation should remain a simple Unix-style shell workflow rather than introducing an external orchestration tool.

Before implementing:

1. inspect the existing dotfiles repository;
2. identify and follow its conventions for Bash scripts, aliases, logging, error handling, configuration, and tests;
3. inspect the repository's existing test mechanisms and use them for testing this functionality.

### Implementation Language

Implement this in Bash.

Treat the script as a CLI orchestrator around Git, tmux, Claude Code, ranger, and lazygit rather than building an application framework.

Use disciplined Bash practices:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

Structure the implementation into small functions rather than one large command dispatcher.

Expected functions may include concepts such as:

```text
cmd_new
cmd_list
cmd_open
cmd_rebase
cmd_done
cmd_cleanup

require_git_repo
validate_branch
get_repo_root
get_repo_name
get_worktree_path
get_base_branch
ensure_tmux_session
create_tmux_window
```

Use repository conventions where they differ from these example names.

Additional requirements:

* do not use `eval`;
* quote paths and variables correctly;
* prefer Bash arrays when constructing commands;
* prefer machine-readable / porcelain output where available;
* prefer commands such as:

```bash
git -C "$path" ...
```

over relying on repeated `cd` side effects;

* fail early before destructive operations;
* keep the implementation readable and maintainable;
* do not introduce Python or another runtime.

### Main Script

Create:

```text
bin/worktrees.sh
```

The script must:

* use Bash;
* be executable;
* only operate when invoked from somewhere inside a Git repository;
* determine the repository root/name automatically;
* support the commands documented below;
* fail safely with clear errors;
* correctly quote paths and names.

Usage:

```text
worktrees.sh new <branch>
worktrees.sh list
worktrees.sh open <branch>
worktrees.sh rebase <branch>
worktrees.sh fi <branch>
worktrees.sh done <branch>
worktrees.sh ri <branch>
worktrees.sh cleanup <branch> [--force]
```

`fi` is an alias for `rebase`.

`ri` is an alias for `done`.

### Worktree Location

Allow the base worktree directory to be overridden with:

```bash
WORKTREES_DIR
```

Default:

```bash
WORKTREES_DIR="$HOME/worktrees"
```

For repository `<repo>` and branch `<branch>`, create the worktree at:

```text
$WORKTREES_DIR/<repo>/<branch>
```

Example:

```text
repo:   dotfiles
branch: feature/foo

~/worktrees/dotfiles/feature/foo
```

It is acceptable and expected that `/` in branch names creates nested directories.

### Branch Names

Branch names:

* maximum length: 80 characters;
* allowed characters:

  * `a-z`
  * `A-Z`
  * `0-9`
  * `-`
  * `_`
  * `/`
* must additionally be valid Git branch names.

Validate using both the explicit rules above and:

```bash
git check-ref-format --branch
```

Do not silently rewrite invalid branch names.

### Base Branch

When `new` is invoked, use the branch currently checked out in the invoking repository/worktree as the base branch.

Example:

```text
current branch: master
wt new feature/foo
```

creates:

```text
feature/foo
```

from:

```text
master
```

Remember the base branch associated with the task/worktree using a simple and robust Git-native or repository-local mechanism.

`rebase`, `done`, and `cleanup` must use that recorded base branch rather than assuming `main` or `master`.

Do not store task metadata inside tracked source files.

### Command: `new`

Usage:

```bash
wt new <branch>
```

Behavior:

1. Verify:

   * currently inside a Git repository;
   * branch name is valid;
   * branch does not already exist;
   * target worktree path does not already exist;
   * required tools are available.

2. Record the currently checked-out branch as the task's base branch.

3. Create the branch and worktree using `git worktree`.

Equivalent conceptually to:

```bash
git worktree add \
    -b "<branch>" \
    "$WORKTREES_DIR/<repo>/<branch>" \
    "<base-branch>"
```

Do not overwrite or reuse an existing branch.

4. Create/open the repository's tmux session and task window as described below.

5. Attach/switch to the newly created task window.

#### Dependencies

Before constructing the tmux window, verify that these commands are available:

```text
git
tmux
claude
ranger
lazygit
```

Fail with a useful message rather than creating a partially initialized tmux workspace.

### tmux Structure

Use:

```text
one tmux session per repository
one tmux window per worktree/task
```

#### Session

The tmux session name should be derived from the repository name.

Example:

```text
repo: dotfiles
tmux session: dotfiles
```

If the session does not exist, create it.

If it already exists, reuse it.

Follow tmux naming constraints safely if a repository name contains characters unsuitable for a tmux session name.

#### Window

The window name is the branch name.

Example:

```text
feature/foo
```

All panes in the window must have their working directory set to that task's worktree root.

#### Pane Layout

The task window contains four panes.

Layout:

```text
┌────────────────────────────┬──────────────────┐
│                            │ ranger           │
│                            ├──────────────────┤
│           Claude           │ lazygit          │
│            67%             ├──────────────────┤
│                            │ shell            │
└────────────────────────────┴──────────────────┘
```

The left pane:

* approximately 67% of total width;
* runs:

```bash
claude --name "<branch>"
```

The right side takes approximately 33% and is split into three approximately equal-height panes:

1. `ranger`
2. `lazygit`
3. normal interactive shell

Set useful pane titles if supported cleanly by the existing tmux configuration:

```text
claude
ranger
lazygit
shell
```

Do not depend on automatic tmux pane/window renaming for task identification.

### Command: `list`

Usage:

```bash
wt list
```

List worktrees managed for the current repository.

Use `git worktree list --porcelain` and normal Git/tmux commands rather than maintaining a duplicate database of worktrees.

Show useful task state in a concise table similar to:

```text
BRANCH                  BASE      TMUX       GIT       AHEAD
feature/auth-timeout    master    running    dirty     2
feature/cache           master    stopped    clean     4
```

Fields:

* `BRANCH` — worktree branch;
* `BASE` — recorded base/integration branch;
* `TMUX` — whether its tmux window currently exists/runs;
* `GIT` — `clean` or `dirty`;
* `AHEAD` — number of commits the task branch is ahead of its base branch.

Only list linked worktrees belonging to the current repository.

Do not include unrelated repositories from `$WORKTREES_DIR`.

Use standard tools such as:

```text
git worktree list --porcelain
git status --porcelain
git rev-list
tmux list-windows
```

as appropriate.

### Command: `open`

Usage:

```bash
wt open <branch>
```

Switch to the tmux session/window corresponding to the specified worktree.

If currently outside tmux, attach to the repository session and select the requested window.

If already inside tmux, switch/select the appropriate session/window without nesting tmux.

Give a clear error if the worktree or tmux window does not exist.

### Command: `rebase` / `fi`

Usage:

```bash
wt rebase <branch>
wt fi <branch>
```

Purpose:

Bring the specified task/worktree up to date with its base branch.

Behavior:

1. Determine the task's recorded base branch.
2. Ensure the task worktree is clean.
3. Ensure the base branch/reference exists.
4. Rebase the task branch onto the current/latest local state of its base branch.

Conceptually:

```bash
git rebase "<base-branch>"
```

performed from the task worktree.

Do not automatically resolve conflicts.

If conflicts occur:

* stop;
* leave the worktree in normal Git rebase-conflict state;
* clearly tell the user that manual/Claude conflict resolution is required.

Never automatically choose `ours` or `theirs`.

This command operates on local Git state only; it should not implicitly `git pull`.

### Command: `done` / `ri`

Usage:

```bash
wt done <branch>
wt ri <branch>
```

Purpose:

Integrate a completed task back into its recorded base branch.

Behavior:

1. Verify the task worktree exists.
2. Verify its working tree is clean.
3. Determine its recorded base branch.
4. Verify the base branch checkout is clean.
5. Rebase the task branch onto the latest local state of the base branch.
6. If the rebase succeeds, integrate the task into the base branch using a fast-forward-only merge:

```bash
git merge --ff-only "<branch>"
```

7. Close/delete the corresponding tmux task window after successful integration.

If rebase or merge encounters a problem:

* stop;
* preserve all Git state;
* do not delete the tmux window, branch, or worktree;
* provide a clear error/action message.

`done` must **not** delete the worktree or branch. Cleanup is intentionally a separate operation.

Add a TODO noting that a future implementation may support creating/pushing a pull request instead of directly merging locally.

### Command: `cleanup`

Usage:

```bash
wt cleanup <branch>
```

Purpose:

Remove a completed task's local resources.

Normal cleanup must refuse if:

* the worktree contains uncommitted changes;
* the branch contains commits not integrated into its recorded base branch.

When safe:

1. close/remove the tmux window if it still exists;
2. remove the worktree using:

```bash
git worktree remove
```

3. delete the local task branch;
4. remove any metadata created specifically for that task;
5. clean up now-empty parent directories under:

```text
$WORKTREES_DIR/<repo>
```

where appropriate.

Do not normally implement cleanup as:

```bash
rm -rf <worktree>
```

because Git worktree metadata must also be removed correctly.

Support:

```bash
wt cleanup <branch> --force
```

`--force` may allow intentional deletion of an unmerged/dirty task, but it must be explicit and should print a clear warning about what is being discarded.

Do not delete the base branch.

### Alias

Add a conditional `wt` alias/function using the repository's existing shell configuration conventions.

The alias should only be defined if:

```text
$DOTFILES/bin/worktrees.sh
```

exists.

Conceptually:

```bash
alias wt="$DOTFILES/bin/worktrees.sh"
```

First inspect how `$DOTFILES`, aliases, and conditional helper scripts are handled elsewhere in this repository and use the existing convention.

Do not introduce an unrelated new shell initialization mechanism.

### Git / Worktree Safety

Keep these properties explicit in the implementation:

* each task gets its own branch;
* each task gets its own worktree;
* multiple worktrees may independently modify the same source files;
* conflicting changes are reconciled later by normal Git rebase/merge conflict resolution;
* worktrees share the underlying Git repository and refs;
* never assume a worktree is equivalent to an independent clone.

Do not manipulate another worktree's files directly when normal Git operations can be used instead.

Use Git commands capable of operating against explicit worktree paths where helpful, for example:

```bash
git -C "<path>" ...
```

This should allow commands to be implemented without relying excessively on `cd` side effects.

### Tests

Tests are required.

Before implementing tests, inspect the dotfiles repository and determine:

* what test framework or test scripts already exist;
* where tests are stored;
* how shell helpers are tested;
* how tests are invoked locally and in CI, if applicable.

Use the existing repository test mechanisms rather than introducing a new testing framework unless there is no reasonable existing mechanism.

The tests should exercise the real Git behavior using temporary repositories/worktrees wherever practical.

Avoid mocking Git logic that can be tested safely with temporary repositories.

tmux behavior may use either:

* real isolated tmux sessions with a test-specific socket/session namespace; or
* existing repository mocking/test conventions,

depending on how the repository currently handles external CLI dependencies.

Tests must not:

* alter the developer's real repositories;
* operate on existing user worktrees;
* interfere with existing tmux sessions;
* modify the user's real `$HOME/worktrees`;
* leave branches, worktrees, tmux sessions, or temporary files behind.

Use temporary directories and a test-specific `WORKTREES_DIR`.

#### Required Test Coverage

At minimum, add automated tests covering:

**General / validation**

* invocation outside a Git repository fails;
* missing/unknown command fails with useful usage information;
* missing required arguments fail;
* invalid branch names are rejected;
* branch names longer than 80 characters are rejected;
* Git-invalid branch names are rejected;
* an already-existing branch is rejected;
* an already-existing target worktree path is rejected;
* `WORKTREES_DIR` override is honored.

**`new`**

* creates the expected branch;
* creates the expected Git worktree;
* creates the expected path:

```text
$WORKTREES_DIR/<repo>/<branch>
```

* branch names containing `/` create the correct nested directory;
* uses the current branch as the recorded base branch;
* creates/reuses the correct tmux session;
* creates the correct tmux window;
* creates four panes;
* all panes use the task worktree as their working directory;
* pane layout is approximately 67% / 33%;
* the expected commands are launched in the correct panes:

  * Claude
  * ranger
  * lazygit
  * shell.

**`list`**

* lists the correct worktrees for the current repository;
* does not include worktrees from unrelated repositories;
* reports the recorded base branch;
* reports clean/dirty state correctly;
* reports commits ahead correctly;
* reports tmux running/stopped state correctly.

**`open`**

* selects the appropriate window when already inside tmux;
* attaches/selects correctly when outside tmux, where practical to test;
* fails clearly for a missing worktree/window.

**`rebase` / `fi`**

* `fi` behaves identically to `rebase`;
* successfully rebases a task onto its base branch;
* refuses a dirty task worktree;
* preserves state when a rebase conflict occurs;
* does not automatically resolve conflicts;
* does not implicitly pull remote changes.

**`done` / `ri`**

* `ri` behaves identically to `done`;
* rebases before integration;
* merges using fast-forward-only semantics;
* integrates into the recorded base branch;
* refuses a dirty task worktree;
* refuses a dirty base worktree;
* preserves the task worktree and branch after integration;
* removes the corresponding tmux window after successful integration;
* does not remove the tmux window when integration fails;
* preserves Git state on conflict/failure.

**`cleanup`**

* removes an integrated task worktree;
* removes the local task branch;
* removes associated metadata;
* removes the tmux window if it exists;
* refuses a dirty worktree;
* refuses an unmerged branch;
* does not delete the base branch;
* `--force` allows explicitly requested cleanup of dirty/unmerged work;
* removes now-empty task directories where appropriate.

**Alias**

* the `wt` alias/function is available when `bin/worktrees.sh` exists;
* it follows the repository's existing shell initialization conventions.

#### Test Cleanup

Every test must clean up after itself even when it fails.

Where supported by the repository's test framework, use setup/teardown helpers or traps so temporary:

```text
repositories
worktrees
branches
tmux sessions
directories
```

are always removed.

Use unique test tmux session/socket names to prevent accidental interaction with normal tmux sessions.

### End-to-End Validation

In addition to focused automated tests, perform an end-to-end validation using a temporary Git repository.

Validate this lifecycle:

1. create a temporary repository and initial base branch;
2. create an initial commit;
3. run `new feature/one`;
4. verify branch/worktree creation;
5. verify worktree path;
6. verify tmux session/window/panes;
7. verify `list`;
8. create and commit a change in the task;
9. update the base branch;
10. run `rebase`;
11. verify successful rebase;
12. create an intentional conflict and verify safe conflict behavior;
13. resolve/abort the conflict as appropriate;
14. complete the task;
15. run `done`;
16. verify the task was integrated;
17. verify the tmux task window was removed;
18. verify the worktree and branch still exist;
19. run `cleanup`;
20. verify worktree, branch, metadata, and tmux state are cleaned up.

Do not leave temporary resources behind.

### Implementation Constraints

* Follow existing dotfiles Bash conventions.
* Follow existing dotfiles test conventions.
* Prefer straightforward Bash over unnecessary abstraction.
* Keep `bin/worktrees.sh` readable and maintainable.
* Use `set -Eeuo pipefail`.
* Quote all variables containing paths/branch names correctly.
* Use Bash arrays for command construction where appropriate.
* Do not use `eval`.
* Prefer machine-readable command output.
* Prefer `git -C` over unnecessary directory changes.
* Avoid external dependencies beyond normal shell tools, Git, tmux, Claude Code, ranger, and lazygit.
* Commands should fail before destructive operations whenever validation fails.
* Do not automatically run `git pull`, push branches, or contact GitHub.
* Do not silently discard local changes.
* Do not automatically resolve Git conflicts.
* Re-running non-destructive commands such as `list` must be safe.
* Preserve useful error output from Git/tmux rather than masking it.
* Tests must be isolated from real repositories, worktrees, and tmux sessions.

## Acceptance Criteria

### Implementation

- [x] `bin/worktrees.sh` exists and is executable.
- [x] Implementation is Bash and uses `set -Eeuo pipefail`.
- [x] Script is structured into small, readable functions.
- [x] Script does not use `eval`.
- [x] Script refuses to operate outside a Git repository.
- [x] `WORKTREES_DIR` defaults to `$HOME/worktrees` and can be overridden.
- [x] Branch names are limited to 80 characters and the specified allowed character set.
- [x] Invalid Git branch names are rejected via `git check-ref-format --branch`.
- [x] `new <branch>` creates a new branch and worktree from the invoking branch.
- [x] `new` refuses an already-existing branch.
- [x] The task's original base branch is remembered for later `rebase`, `done`, and `cleanup` operations.
- [x] Worktree paths follow `$WORKTREES_DIR/<repo>/<branch>`.
- [x] One tmux session is used per repository.
- [x] One tmux window is used per task branch.
- [x] Claude occupies approximately 67% of the tmux window.
- [x] The remaining area contains ranger, lazygit, and shell panes.
- [x] All four panes start in the task worktree root.
- [x] Claude starts with `claude --name "<branch>"`.
- [x] `list` reports branch, base, tmux state, Git cleanliness, and commits ahead.
- [x] `open <branch>` selects/attaches to the correct tmux task window.
- [x] `rebase` and `fi` behave identically.
- [x] `rebase` rebases onto the recorded base branch and safely stops on conflicts.
- [x] `done` and `ri` behave identically.
- [x] `done` rebases and then fast-forward merges into the recorded base branch.
- [x] `done` closes the task tmux window after successful integration.
- [x] `done` leaves the branch/worktree intact.
- [x] `cleanup` safely removes the tmux window, Git worktree, branch, and task metadata.
- [x] Normal cleanup refuses dirty or unmerged work.
- [x] `cleanup --force` explicitly supports intentional discard.
- [x] A conditional `wt` alias is added following existing dotfiles shell conventions.

### Testing

- [x] Existing dotfiles test mechanisms are used.
- [x] Automated tests are added for all major commands.
- [x] Tests cover validation and failure paths, not only successful flows.
- [x] Tests verify base-branch tracking.
- [x] Tests verify nested paths for branch names containing `/`.
- [x] Tests verify dirty/unmerged safety checks.
- [x] Tests verify conflict handling without data loss.
- [x] Tests verify `rebase`/`fi` equivalence.
- [x] Tests verify `done`/`ri` equivalence.
- [x] Tests verify tmux session/window/pane creation.
- [x] Tests are isolated from normal user tmux sessions.
- [x] Tests use temporary repositories/worktrees.
- [x] Tests clean up all temporary resources.
- [x] End-to-end workflow validation passes.
- [x] Existing dotfiles tests continue to pass.

## Out of Scope

* GitHub pull-request creation or merging; leave a TODO for this.
* Automatic `git pull` / remote synchronization.
* Automatic branch push/delete on remotes.
* Multi-agent orchestration beyond one Claude Code process per task window.
* Runtime isolation for Docker containers, ports, databases, or external services.
* Automatic Git conflict resolution.
* Monitoring Claude semantic state such as waiting-for-input versus actively working.
* Replacing tmux with another session manager.

## Edge Cases / Test Scenarios

<!-- Optional. List non-obvious inputs or states to handle.  -->
<!-- Requirements agent will fill this in if left blank.     -->

## Questions

<!-- Triage agent appends here when clarification is needed. -->
<!-- Remove this section once all questions are resolved.    -->

## Assumptions

<!-- Requirements agent appends documented assumptions here. -->

## Implementation Notes

- Two real bugs were found and fixed in the pre-existing (uncommitted) draft of `bin/worktrees.sh` before closing out this task:
  1. **tmux pane targeting used hardcoded `.0`-`.3` indices**, which assumes `pane-base-index 0`. This breaks under this user's own `tmux/.tmux.conf`, which sets `pane-base-index 1` — `tmux split-window -t "$target.0"` fails with `can't find pane: 0`. Fixed by capturing each pane's id (`%N`, via `-P -F '#{pane_id}'` on `new-session`/`new-window`/`split-window`) and targeting by id everywhere instead of by index. This is also immune to any other `pane-base-index` value.
  2. **`tmux split-window -p <percent>` fails with `size missing`** on a session/window that no client has ever attached to — which is always true immediately after `new-session`/`new-window` for a brand-new task, before `open`/attach happens. Reproduced directly with plain tmux commands (no wrapper script involved) to confirm it's a tmux behavior, not a script bug. Fixed by querying the pane's actual live width/height (`tmux display-message -p '#{pane_width}'`/`'#{pane_height}'`) and computing absolute `-l <cells>` sizes instead of `-p <percent>`.
- `tests/test-cases/test-worktrees.sh` declares `# REQUIRES: git tmux` only. `claude`, `ranger`, and `lazygit` are stubbed with fake PATH executables rather than requiring them genuinely installed, so `new`'s dependency check and pane commands can be exercised without depending on, or actually launching, those tools. Isolation: a temp `WORKTREES_DIR`, a dedicated `TMUX_TMPDIR` tmux server, and temp git repos — nothing touches the real `$HOME/worktrees` or the developer's own tmux sessions/repos.
- The "missing dependency" test (`new` failing when `ranger` is absent) uses a curated PATH of symlinks to the real `git`/`tmux`/coreutils plus stubbed `claude`/`lazygit`, deliberately omitting `ranger` — simply removing `ranger` from a prepended stub directory isn't sufficient since the real `ranger` may still be genuinely installed elsewhere on the host PATH (as it is on this dev machine).
- Two `noclobber` test bugs were found and fixed during Docker validation: `bash/options.sh` sets `set -o noclobber` for interactive shells, and `tests/run-tests.sh` invokes test files inside Docker via `bash -li` (interactive login), so several `echo ... >file` redirects that overwrote already-existing fixture files needed to become `>|` to force the overwrite. These passed locally (plain `bash test-worktrees.sh`, no noclobber) but failed only under `bash -li`/Docker, so were only caught by actually validating in that environment.
- The alias test deliberately does **not** source the full `sh/setenv.sh` chain (it pulls in ~10 other files — `path.sh`, `sysinfo.sh`, `git.sh`, `docker.sh`, etc. — with their own environment assumptions, which proved fragile under the minimal Arch test container). It instead checks the literal source line's content plus a narrow reproduction of the conditional-alias pattern, matching the existing precedent in `tests/test-cases/test-git-env.sh` (which sources `git/git.sh` directly for the same reason).
- The `wt` alias uses `$dotdir` (this repo's actual shell-env variable, set in `bash/.bashrc`/`zsh/.zshrc`) rather than the task description's generic `$DOTFILES` placeholder, added to `sh/setenv.sh` following the existing conditional-source convention used there for `git/git.sh` and `docker/docker.sh`.
- `tests/test-cases/test-remote-configure.sh` has a pre-existing, unrelated locale-generation race in the Debian remote test container (`bash: warning: setlocale: LC_ALL: cannot change locale`) that also fails on `master` without any of this task's changes. Confirmed via `git stash` before re-running it. Out of scope for this task; left as-is.
- `docs/coding-conventions/cc-bash-01.md` calls for `shfmt`-formatted scripts, but the existing codebase (e.g. `setup/setup_functions.sh`) is not `shfmt`-clean under default settings and there is no `.editorconfig` pinning a style, so `bin/worktrees.sh` and the new test file were hand-formatted to match the codebase's actual prevailing style instead of running `shfmt -w`, which would have produced an inconsistent mix within the same files.
