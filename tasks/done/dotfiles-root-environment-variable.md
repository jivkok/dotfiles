# Task: Dotfiles Root Environment Variable

**Status**: done
**Priority**: medium
**Created**: 2026-10-31

## Description

Introduce a DOTFILES environment variable as the single source for the dotfiles repo location

## Acceptance Criteria

Shell bootstraps (`bash/.bashrc`, `zsh/.zshrc`)
- [x] `bash/.bashrc` and `zsh/.zshrc` set `export DOTFILES="${DOTFILES:-$HOME/dotfiles}"` and then a plain (unexported) `dotdir="$DOTFILES"`, replacing the hardcoded `export dotdir="$HOME/dotfiles"`; the sourced files keep using `$dotdir` unchanged.
- [x] With `DOTFILES` unset, a login `bash` and `zsh` shell (HOME isolated) end up with `DOTFILES=$HOME/dotfiles` and `dotdir=$HOME/dotfiles`, with `dotdir` not exported.
- [x] With `DOTFILES=/some/other/path` set in the environment, a login `bash` and `zsh` shell source `/some/other/path/{bash,zsh}/setenv.sh` (not `~/dotfiles`).

Setup writes the location
- [x] `setup/configure_shell_profiles.sh` ensures `~/.bashrc` and `~/.zshrc` each contain exactly one line `export DOTFILES="<absolute path of the repo it runs from>"` above the `source ".../setenv.sh"` line; the line is added when missing and its value is replaced when it differs.
- [x] Running `configure_shell_profiles.sh` twice leaves `~/.bashrc` and `~/.zshrc` byte-identical after the second run.
- [x] After `configure_shell_profiles.sh` is run from a copy of the repo at a non-default path (e.g. `$TMP/my-dots`) with an isolated HOME and `DOTFILES` unset, a new login `bash` and `zsh` shell report `DOTFILES=$TMP/my-dots` and have `$TMP/my-dots/bin` on `PATH`.

Consumers of the location
- [x] `sh/path.sh` prepends `$DOTFILES/bin` to `PATH` instead of `$HOME/dotfiles/bin`.
- [x] `update_os` in `sh/system.sh` pulls `$DOTFILES` instead of `$HOME/dotfiles`.
- [x] `grep -rnE 'HOME/dotfiles|~/dotfiles'` over `bash/ zsh/ sh/ setup/*.sh` finds only the documented default in the two bootstraps and the remote-deploy default (`setup/deploy-remote-vm.sh`).
- [x] `setup/setup-remote-vm.sh` and `setup/deploy-remote-vm.sh` keep the remote location `~/dotfiles` (unchanged behavior); the remote bootstrap resolves `DOTFILES` to `~/dotfiles` through the same default.

Windows
- [x] `setup/setup.ps1` takes its `$dotfiles` parameter default from `$env:DOTFILES` when set, else `$HOME\dotfiles`, and persists `DOTFILES` as a user-level environment variable (`[Environment]::SetEnvironmentVariable('DOTFILES', <path>, 'User')`); re-running it leaves the value unchanged.
- [x] `windows/SetEnv.ps1` and `windows/SetEnv.cmd` need no hardcoded `dotfiles` path; any reference to the repo root uses `$env:DOTFILES` / `%DOTFILES%` with the `%USERPROFILE%\dotfiles` default.
- [x] Manually verified on a Windows machine (no automated Windows test environment exists): after `setup.ps1`, a new PowerShell session shows `$env:DOTFILES` set to the repo path. The result is recorded in Implementation Notes.

Tests and docs
- [x] A test (extending `tests/test-cases/test-startup-bash.sh` / `test-startup-zsh.sh`, or a new covered test) implements the three shell-level criteria above (default, env override, setup from a non-default path) with an isolated HOME and passes on local, Debian and Arch environments.
- [x] `tests/test-cases/helpers/startup-checks.sh` additionally asserts `~/.bashrc` and `~/.zshrc` contain `DOTFILES`.
- [x] `docs/structure.md` documents `DOTFILES`: its default, who sets it, and the split of responsibilities: `DOTFILES` is the external setting used only by the bootstraps; `dotdir` is the internal value, derived by each executable from its location and set once by the bootstrap for sourced files.
- [x] The full suite (`/run-tests --full`) passes.

## Out of Scope

- The tmux change (`$DOTFILES/bin/tmux-helper.py`, `@th`/`@py` options, removing the `~/bin` and fragment symlinks); that is a separate follow-up task that depends on this one.
- Support for a non-default location on remote VMs (the remote stays `~/dotfiles`).
- Changing how setup scripts derive their own `dotdir` from `$(dirname "$0")/..`; that is already location-independent and stays as is.
- `windows/console.xml` (terminal emulator config with a hardcoded `%USERPROFILE%\dotfiles` path) and `README.md` clone instructions beyond one note about `DOTFILES`.
- Moving or cloning the repo; the task only makes an already-placed repo findable.

## Edge Cases / Test Scenarios

- `DOTFILES` set but pointing to a non-existent directory: the shell bootstrap still exports it; sourcing `setenv.sh` fails as it does today for a missing `~/dotfiles` (no new guard added).
- Path containing spaces: `~/.bashrc`/`~/.zshrc` line and sourcing work when `DOTFILES="/tmp/my dots"` (quoted everywhere).
- Existing `~/.bashrc` created by an older version (contains `export dotdir="$HOME/dotfiles"` and no `DOTFILES` line): after `configure_shell_profiles.sh`, the new lines are merged in and the shell resolves the location from `DOTFILES`, not the stale hardcoded line. Assumption: the old `export dotdir="$HOME/dotfiles"` line is removed by setup so it cannot override.
- `~/.bashrc` already has a `DOTFILES` line with a different path: it is replaced, not duplicated.
- Trailing slash or symlinked repo path: setup writes the `pwd -P`-normalised absolute path without a trailing slash.
- `DOTFILES` exported in the environment differs from the line setup wrote: the environment value wins (`${DOTFILES:-...}` semantics), since the written line is only a default for shells that start without it.
- zsh and bash non-login interactive shells both resolve the same value.

## Assumptions

- Responsibilities are split: `DOTFILES` is the only exported/external variable and is read only by the bootstraps; `dotdir` is internal, never exported and never read from the environment: executables derive it from `dirname "$0"`, sourced files get it from the bootstrap (`dotdir="$DOTFILES"`). This includes `bin/configure_fonts.sh` (its `DOTFILES_ROOT` override is removed) and `bin/worktrees.sh`.
- The bootstrap is merged by `append_or_merge_file` (appends missing lines only), so setup cannot rely on the repo's static bootstrap to carry an absolute path; `configure_shell_profiles.sh` therefore inserts/updates the `export DOTFILES=...` line itself, always with the absolute path (even for the default location).
- The hardcoded old line `export dotdir="$HOME/dotfiles"` in an already-configured `~/.bashrc`/`~/.zshrc` is removed by setup; this is the only case where setup deletes a line from those files.
- Remote VM keeps `~/dotfiles`; its bootstrap just goes through the same default.
- Per-script `dotdir="$(cd "$(dirname "$0")/.." && pwd)"` in setup/configure scripts is unaffected and not renamed.
- Windows has no automated tests; `setup/setup.ps1` is verified manually by the user/implementer and the result is noted in Implementation Notes.
- Windows PowerShell profile contents are managed elsewhere; persisting `DOTFILES` as a User-level environment variable is enough, no profile edit.
- `README.md` gets at most a one-line note; its `~/dotfiles` clone paths stay as the recommended default.

## Implementation Notes

- The pinned line is `export DOTFILES="${DOTFILES:-<abs path>}"` (not a bare assignment) so that an exported `DOTFILES` still wins, per the edge-case list. `set_dotfiles_root` (setup/setup_functions.sh) rewrites the two-line `DOTFILES`/`dotdir` block above the `source "$dotdir/<shell>/setenv.sh"` line (also converting the intermediate `$DOTFILES` source form), so it works for fresh, merged and legacy profiles. `append_or_merge_file` still appends the repo's bootstrap lines on every run and `set_dotfiles_root` removes them again; the end state is byte-identical.
- The grep criterion also matches `setup/setup_functions.sh`, which contains the `$HOME/dotfiles` default as text it writes into profiles.
- `windows/SetEnv.ps1` / `SetEnv.cmd` contain no hardcoded repo path, so they needed no change; `windows/console.xml` is left as is (out of scope).
- `setup.ps1`: `$dotfiles` defaults to `$env:DOTFILES` if set, and `DOTFILES` is persisted as a User variable (and set for the current session) only when it differs.
- Tests: new `tests/test-cases/test-dotfiles-root.sh` (39 checks: default, env override, setup from a path with a space, idempotence, env-wins, legacy profile) plus `DOTFILES` assertions in `startup-checks.sh`. Full suite: 71 passed, 0 failed (local, Debian, Arch).
- Windows criteria (`setup.ps1` default/persistence and the new-session `$env:DOTFILES` check) were confirmed on a Windows machine by the user; no output was recorded here. The same `setup.ps1` also carries the user's separate Windows cleanup changes (self-elevation, Chocolatey source, etc.), which are outside this task.
