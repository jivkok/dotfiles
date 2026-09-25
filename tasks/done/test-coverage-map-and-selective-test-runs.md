# Task: Test Coverage Map, Selective Test Runs, and Coverage for Non-Setup Scripts

**Status**: done
**Priority**: high
**Created**: 2026-09-22

## Description

Improve test coverage and suite stability. Today, setup and shell-startup scripts are well
covered, but scripts that don't run during setup (function libraries in `sh/`, tools in `bin/`,
`docker/docker.sh`, `ai/*`, and others) have little or no coverage. The suite also always runs as
one block: every test, in every environment, on every change.

### Current state (analysis, 2026-09-22)

**Coverage today** (15 test files in `tests/test-cases/`):

| Area | Covered by |
|------|-----------|
| `setup/setup.sh` + configure scripts it calls | `test-startup-bash.sh`, `test-startup-zsh.sh` (via `helpers/startup-checks.sh`, which checks results: commands, symlinks, files) |
| `setup/setup_functions.sh` | `test-setup-functions.sh` (unit) |
| `setup/setup-remote-vm.sh`, `setup/deploy-remote-vm.sh` | `test-remote-configure.sh` |
| `git/configure_git.sh`, `git/git.sh` | `test-git-configure.sh`, `test-git-env.sh` |
| `bin/worktrees.sh` | `test-worktrees.sh` (unit + isolated tmux) |
| `python`, `nodejs`, `go`, `dotnet`, `docker`, `vim` configure | `test-*-configure.sh`: smoke tests that check binaries exist, not script logic |
| `vscode/configure_vscode.sh`, `osx/configure_browsers.sh` | `test-vscode-configure.sh`, `test-browsers-configure.sh`, but they test **copies** of the functions (see gap 2) |

**No coverage at all** (~2,900 lines): `sh/utils.sh` (318), `sh/system.sh` (213), `sh/finds.sh` (190),
`sh/sysinfo.sh` (167), `sh/marks.sh`, `sh/path.sh`, `sh/edits.sh`, `sh/web.sh`, `sh/ls.sh`, `sh/helpers.sh`,
`bin/configure_fonts.sh` (282), `bin/tmux-session-save.sh`, `bin/tmux-session-restore.sh`,
`bin/tmux-status-cpu.sh`, `bin/tmux-status-ip.sh`, `docker/docker.sh`, `ai/configure_ollama.sh`,
`ai/configure_ollama_models.sh`, `ai/configure_opencode.sh`, `ai/claude-code/claude-code-docker.sh` (273),
`ai/claude-code/entrypoint.sh`, `linux/generate_distro_package_setup_code.sh`, `rust/configure_rust.sh`,
`sublimetext/configure_sublimetext.sh`, `tmux/osc52.sh`. The startup tests only prove that
`bash/*.sh` and `zsh/*.sh` load without errors.

### Gaps

1. **Docker runs test stale code for non-setup scripts.** `run-tests.sh` bind-mounts only `tests/`
   into the container. Everything else comes from the repo copy baked into the image at build time.
   The image hash (`create-test-envs.sh`) covers only setup files, so a change to `bin/worktrees.sh`,
   `sh/*.sh`, `git/git.sh`, etc. **never rebuilds the image**. Docker runs keep testing the old
   version, and new files are missing entirely. Every non-setup test is affected in Docker.
2. **Copied helpers have drifted from the real code.** `tests/test-cases/helpers/vscode-functions.sh`
   and `helpers/browsers-functions.sh` are hand-maintained copies ("kept in sync") because of gap 1.
   They have already drifted:
   - `browsers-functions.sh` defines `ensure_firefox_profiles_ini`, `create_firefox_profile_if_absent`,
     and `write_firefox_prefs_js`. None of these exist in `osx/configure_browsers.sh`, which has
     `create_firefox_profile`, `write_firefox_user_js`, and `install_extensions_into_profile`.
     `install_firefox_extension` is implemented differently: raw curl vs `download_file`.
   - `test-browsers-configure.sh` therefore passes against code that doesn't ship.
3. **No test mapping.** Nothing links a script to the tests that exercise it, so you can't run
   only the relevant tests, and you can't detect a new script that has no tests.
4. **Monolithic runner.** Every run rebuilds or validates envs, then runs every selected test in
   every environment. The only selector is `--filter <cmd>`, which matches `REQUIRES`, not the
   code under test.
5. **No static checks.** Nothing runs `bash -n` / `zsh -n` / `shellcheck` over the repo, even though
   `.shellcheckrc` exists and `shellcheck` is installed by setup. Syntax errors in rarely run scripts
   go unnoticed.
6. **Smoke-only configure tests.** The python/nodejs/go/dotnet/docker/vim tests check that
   binaries exist, not that the scripts are idempotent. AGENTS.md requires idempotence, but no
   test checks it.

### Proposed approach

**Phase 1: Run Docker tests against the working tree (fixes gaps 1–2)**
- Mount the working-tree repo into Docker test containers, not just `tests/`, so non-setup
  scripts under test are current. The image still supplies setup results: packages, generated
  files, `$HOME` symlinks. Setup-affecting changes still trigger an image rebuild through the
  existing hash.
- Make `vscode/configure_vscode.sh` and `osx/configure_browsers.sh` sourceable without side effects,
  using a main guard (`[[ "${BASH_SOURCE[0]}" == "$0" ]] && main "$@"`) per `docs/coding-conventions.md`.
  Point the tests at the real scripts, delete `helpers/vscode-functions.sh` and
  `helpers/browsers-functions.sh`, and rewrite `test-browsers-configure.sh` against the functions
  that actually exist.

**Phase 2: Coverage map + selective runs (gaps 3–4)**
- Add a `# COVERS:` header to each test file, alongside the existing `# REQUIRES:` convention.
  It holds a space-separated list of repo-relative paths or globs, e.g.
  `# COVERS: bin/worktrees.sh sh/setenv.sh`. The startup tests list the setup/profile files they
  exercise.
- Add `tests/coverage-exclude` (path/glob + reason per line) for scripts deliberately left untested.
- Add `run-tests.sh --changed [<git-ref>]`. It selects tests whose `COVERS` matches files changed
  vs `<git-ref>` (default `HEAD`: staged + unstaged + untracked). Selection rules:
  - A changed test file selects itself.
  - Changes to `tests/testlib.sh`, `tests/run-tests.sh`, or `tests/create-test-envs.sh` select
    the full suite.
  - A changed file under `tests/test-cases/helpers/` selects the tests that source it.
  - A change to any file in the setup hash (docs/testing.md, "Setup Files Per OS") selects the
    full suite.
  - A changed script that is neither covered nor excluded prints a warning and selects the full
    suite (fail safe).
  - Non-script changes (docs, `tasks/`, `*.md`) select nothing, and the runner exits 0 with
    "No tests selected".
  - `--changed` combines with the existing `REQUIRES` skipping and applies to local and Docker runs.
- Add `run-tests.sh --list [--changed ...]`, which prints the selected tests and their `COVERS`
  without running them (useful for review and for testing the selector itself).
- Add a meta test (`test-coverage-map.sh`) that fails when a tracked script (`*.sh`, `*.zsh`,
  `bin/*`) matches neither a `COVERS` entry nor `tests/coverage-exclude`, or when a `COVERS`
  entry matches no file (stale mapping).

**Phase 3: Static checks (gap 5)**
- Add `test-lint.sh` (`# COVERS: **/*.sh`). It runs `bash -n` on bash scripts, `zsh -n` on zsh
  scripts, and `shellcheck` (honouring `.shellcheckrc`) on bash/sh scripts. When the runner passes
  the changed-file list (e.g. via a `CHANGED_FILES` env var), it lints only those files;
  otherwise it lints everything. Fix or explicitly `# shellcheck disable=` existing findings so
  the test passes.

**Phase 4: New tests for uncovered scripts (gap 6 and the coverage list)**, in priority order:
1. `sh/*.sh` function libraries: unit tests that source the file and call functions with temp
   dirs/files, run under both bash and zsh where the file is loaded by both shells.
2. `bin/tmux-session-save.sh` / `bin/tmux-session-restore.sh`: round-trip on an isolated tmux
   server (reuse the `TMUX_TMPDIR` isolation pattern from `test-worktrees.sh`).
3. `bin/tmux-status-cpu.sh` / `bin/tmux-status-ip.sh`: output format, using stubbed inputs where
   the source is OS-specific.
4. `docker/docker.sh` helpers and `ai/claude-code/claude-code-docker.sh`: argument parsing and the
   generated `docker` invocation, with `docker` stubbed on `PATH`.
5. `ai/configure_ollama*.sh`, `ai/configure_opencode.sh`, `rust/configure_rust.sh`,
   `bin/configure_fonts.sh`: guard/skip logic and idempotence (second run makes no changes), with
   network/installers stubbed.
6. `linux/generate_distro_package_setup_code.sh`: golden-output test.
7. Idempotence checks for the configure scripts already covered by smoke tests, where they can
   be re-run cheaply.

**Tooling/docs**
- `/run-tests` (`.claude/commands/run-tests.md`) defaults to `--changed` and runs the full suite
  when invoked with `--all`/`--full`. AGENTS.md "Agent Validation Steps" is updated so agents run
  `--changed` during iteration and the full suite before reporting a task done.
- `docs/testing.md` documents the `COVERS` header, `coverage-exclude`, `--changed`, `--list`, the
  lint test, and the working-tree mount. It also removes the "kept in sync" helper guidance.

## Acceptance Criteria

### Phase 1: Working-tree Docker runs and real-code helpers

- [x] `run-tests.sh` mounts the working-tree repo into every Docker test container, not just
      `tests/`. Verification: add `return 1` as the first line of `_has` in `sh/helpers.sh`, run
      `bash tests/run-tests.sh` without rebuilding any image, and check that at least one test fails
      in each Docker image. Then revert.
- [x] Adding a new file under `bin/` makes it visible inside the Docker test container at test time
      without an image rebuild.
- [x] `tests/test-cases/helpers/vscode-functions.sh` and `tests/test-cases/helpers/browsers-functions.sh`
      are deleted.
- [x] Running `bash -c 'source vscode/configure_vscode.sh'` performs no installs, copies, or
      network calls. It only defines functions (enforced by a main guard).
- [x] Running `bash -c 'source osx/configure_browsers.sh'` on Linux performs no side effects and
      exits 0.
- [x] `test-vscode-configure.sh` sources `vscode/configure_vscode.sh` directly.
- [x] `test-browsers-configure.sh` sources `osx/configure_browsers.sh` directly and tests each of
      `create_firefox_profile`, `install_firefox_extension`, `write_firefox_user_js`, and
      `install_extensions_into_profile` (≥1 assertion each). It asserts nothing about the removed
      `ensure_firefox_profiles_ini`, `create_firefox_profile_if_absent`, or `write_firefox_prefs_js`.

### Phase 2: Coverage map

- [x] Every `tests/test-cases/test-*.sh` has exactly one `# COVERS:` line within its first 15 lines.
- [x] `tests/coverage-exclude` exists. Each non-comment line has the form
      `<path-or-glob>  # <reason>`, and a line without a reason makes `test-coverage-map.sh` fail.
- [x] `test-coverage-map.sh` exits non-zero and names the file when a tracked `*.sh`, `*.zsh`, or
      `bin/*` file matches neither any `COVERS` entry nor `tests/coverage-exclude`.
- [x] `test-coverage-map.sh` exits non-zero and names the entry when a `COVERS` or
      `coverage-exclude` entry matches no tracked file.
- [x] `test-coverage-map.sh` passes on the final repo state.

### Phase 2: `--changed` selection (one rule per criterion)

Each rule below has a runner self-test that checks `--list --changed` output against a temp git
repo or a stubbed changed-file list.
- [x] Rule A: when only `tests/test-cases/test-X.sh` changed, `--changed` selects exactly `test-X.sh`.
- [x] Rule B: when `tests/testlib.sh`, `tests/run-tests.sh`, or `tests/create-test-envs.sh`
      changed, `--changed` selects every test.
- [x] Rule C: when `tests/test-cases/helpers/H.sh` changed, `--changed` selects exactly the test
      files that reference `helpers/H.sh`.
- [x] Rule D: when any file in the setup hash (as computed by `create-test-envs.sh`) changed,
      `--changed` selects every test.
- [x] Rule E: when a script that is neither covered nor excluded changed, `--changed` prints a line
      starting `WARN: unmapped` with that path and selects every test.
- [x] Rule F: when only non-script files changed (`*.md`, `tasks/**`, `docs/**`), `--changed`
      prints `No tests selected.` and exits 0.
- [x] Rule G: when a script covered by test files T1..Tn changed, `--changed` selects exactly T1..Tn
      (plus `test-lint.sh`, and `test-coverage-map.sh` for Rule H).
- [x] Rule H: when a file was added, deleted, or renamed, `--changed` also selects
      `test-coverage-map.sh`.
- [x] `--changed` with no ref compares against `HEAD` and includes staged, unstaged, and untracked
      (non-ignored) files. `--changed <ref>` compares `<ref>...` plus the working tree.
- [x] `--changed <bad-ref>`, or running outside a git work tree, exits non-zero with an `ERROR:`
      message before any test runs.
- [x] `--changed` still applies `REQUIRES` skipping, and applies the same selection to local and
      Docker runs.
- [x] `--list` prints each selected test with its `COVERS` value, one per line, and exits 0 without
      running tests or `create-test-envs.sh`. It works alone and with `--changed`.
- [x] `--all`, `--filter <cmd>`, `--log-level`, and no-flag runs behave exactly as before (the
      same tests are selected as on `master` before this task).

### Phase 3: Lint

- [x] `test-lint.sh` runs `bash -n` on every tracked bash/sh script, `zsh -n` on every file under
      `zsh/` and every `*.zsh`, and `shellcheck` (honouring `.shellcheckrc`) on every tracked
      bash/sh script. It skips `*.ps1` and `*.py`.
- [x] When `CHANGED_FILES` (newline-separated repo-relative paths) is set by the runner,
      `test-lint.sh` checks only those files. Otherwise it checks all files.
- [x] `test-lint.sh` passes on the final repo state. The 39 shellcheck findings present at
      2026-09-22 are fixed or suppressed with an inline `# shellcheck disable=SCxxxx  # <reason>`.

### Phase 4, item 1: `sh/*.sh` unit tests (`test-sh-libs.sh` or one file per lib)

Each assertion runs under bash. The `helpers.sh`, `path.sh`, and `marks.sh` assertions also run
under zsh, because those files have shell-specific syntax or branches.
- [x] `helpers.sh`: `_has` returns 0 for `sh` and 1 for a nonexistent command.
- [x] `path.sh`: `_prepend_to_path <existing-dir>` prepends it. Calling it twice leaves one entry,
      and a nonexistent dir leaves `PATH` unchanged. The same three assertions hold for
      `_prepend_to_manpath`.
- [x] `marks.sh` (with `MARKPATH` set to a temp dir): `mark foo` creates a symlink to `$PWD`;
      `mark` with no argument returns 1; `mark foo` again returns 1 and prints `already exists`;
      `to foo` changes directory to the target; `to nope` prints `No such mark: nope`; `marks`
      prints `foo` and `->` and the target; `echo y | unmark foo` removes the symlink.
- [x] `utils.sh` `ex`: extracts a `.tar.gz` and a `.tar` created in the test; prints
      `is not a valid file` for a missing path; prints `cannot be extracted` for `x.unknown`.
- [x] `utils.sh` `lsz`: returns 1 with no arguments; lists the members of a test `.tar.gz`.
- [x] `utils.sh` `targz <dir>`: produces `<dir>.tar.gz`, which contains the dir's files.
- [x] `utils.sh` `encode`/`decode`: round-trip `a b&c/é` for each of `url`, `base64`, and `html`
      (the `html` case is skipped if `python3` is absent). `encode url 'a b'` outputs `a%20b`. An
      unsupported encoding prints `Unsupported encoding`.
- [x] `utils.sh` `json`: `echo '{"a":1}' | json` outputs valid JSON containing `"a": 1`.
- [x] `utils.sh` `jdiff`: returns 1 with the wrong argument count, with a missing path, and with
      dir-vs-file. It returns 0 for identical files and non-zero for differing files.
- [x] `utils.sh` `dataurl` on a text file outputs a string starting `data:text/plain;charset=utf-8;base64,`.
- [x] `utils.sh` `codepoint A` outputs `U+0041`.
- [x] `system.sh` `mkd a/b` (run in a subshell) creates `a/b` and ends with `PWD` in `a/b`.
      `paths` prints one `PATH` entry per line.
- [x] `web.sh` `urlencode 'a b&c'` outputs `a+b%26c` (skipped if `python3` is absent).
- [x] `edits.sh`, `finds.sh`, `sysinfo.sh`, and `ls.sh` source without error under bash and zsh
      with `set -u`, and after sourcing, each function they declare (e.g. `f d ff fs fsf fp fpf`
      in `finds.sh`) is defined (`type <fn>` succeeds). Interactive (fzf/editor/network) behaviour
      is not exercised.
- [x] `sh/setenv.sh` sources cleanly with `dotdir` set to the repo (covers the aggregate loader).

### Phase 4, item 2: tmux session save/restore (`test-tmux-session.sh`, `# REQUIRES: tmux`)

Uses an isolated tmux server (`TMUX_TMPDIR`) and `TMUX_SESSION_SAVE_DIR` pointing at a temp dir.
- [x] After save, for a session `s1` with window `w1` (2 panes, distinct cwds) and window `w2`
      (1 pane), `windows.tsv` has 2 lines and `panes.tsv` has 3 lines containing both cwds.
- [x] After killing the server and restoring, `s1` exists with windows `w1` (2 panes) and `w2`
      (1 pane), and each pane's `pane_current_path` equals the saved cwd.
- [x] Restore leaves an existing non-default session with the same name unchanged (same window
      count) and names it in the `skipped existing` message.
- [x] Restore adopts a pre-existing lone-default session (1 window, 1 idle shell pane) with the
      same name, renaming its window to the first saved window name.
- [x] Restore exits 1 when `windows.tsv` or `panes.tsv` is missing.

### Phase 4, item 3: tmux status scripts (`test-tmux-status.sh`)

`bin/tmux-status-cpu.sh` and `bin/tmux-status-ip.sh` get a main guard so their functions can be
sourced.
- [x] `color_for`: 49→`green`, 50→`yellow`, 79→`yellow`, 80→`red`.
- [x] On Linux, `tmux-status-cpu.sh cpu`, `ram`, and `all` each exit 0 and output an integer
      percentage in 0–100.
- [x] `tmux-status-cpu.sh bogus` and `tmux-status-ip.sh bogus` each exit 1 and print `Usage:` to
      stderr.
- [x] `get_external_ip` with a fresh cache file in a temp `TMPDIR` prints the cached value and never
      invokes `curl`. This is checked with a `curl` stub on `PATH` that records calls.
- [x] `get_external_ip` with a cache file older than `CACHE_TTL` calls the `curl` stub, prints its
      output, and rewrites the cache.
- [x] `get_external_ip`, when every service returns empty (stubs for `curl` and `dig`), exits 0 and
      doesn't create a cache file.

### Phase 4, item 4: Docker helpers (`test-docker-helpers.sh`, no `REQUIRES`; `docker`, `curl`, `jq` stubbed)

- [x] `docker_tags` with no arguments returns 1 and prints `Usage:`.
- [x] `docker_tags ubuntu` requests a URL containing `repositories/library/ubuntu/tags`.
      `docker_tags me/img` requests one containing `repositories/me/img/tags`.
- [x] `docker_tags ubuntu 22 1` makes exactly 1 page request and prints only lines matching `22`.
- [x] `docker.sh` defines the `dps` alias and the `dexbash` function when `docker` is on `PATH`,
      and neither when it's absent.
- [x] `claude-code-docker.sh` has these stubs: a `docker` stub whose `images` output includes
      `ai-claude-code:1.2.3.<BUILD>` and whose `run` writes its args to a file, and a version-check
      stamp file dated today. With those stubs, the recorded `run` args contain
      `-v <cwd>:/workspace`, the image tag, and `claude --permission-mode auto`.
- [x] `claude-code-docker.sh '~/x:/x'` records `-v $HOME/x:/x` and `--add-dir /x`.
- [x] `claude-code-docker.sh`, with a `.aiproj` in cwd listing `volumes: [ - /a:/b ]` and without
      `yq` on `PATH`, records `-v /a:/b` and `--add-dir /b`.
- [x] `claude-code-docker.sh` records `-e ANTHROPIC_API_KEY=...` only when `ANTHROPIC_API_KEY` is set.
- [x] `claude-code-docker.sh`, with no image tagged for the current BUILD and a `curl` stub
      returning `garbage`, exits 1 with `couldn't resolve`.
- [x] `claude-code-docker.sh`, with a `curl` stub returning a newer version than the tagged image,
      invokes `docker build` with `CLAUDE_CODE_VERSION=<new>`.
- [x] `claude-code-docker.sh` runs `XDG_STATE_HOME` in a temp dir, so the test writes nothing to the
      real `~/.local/state`.

### Phase 4, items 5–7

- [x] Each of `ai/configure_ollama.sh`, `ai/configure_ollama_models.sh`, `ai/configure_opencode.sh`,
      `rust/configure_rust.sh`, `bin/configure_fonts.sh`, and `linux/generate_distro_package_setup_code.sh`
      is either covered by a test or listed in `tests/coverage-exclude` with reason
      `TODO: test (follow-up)`.

### Tooling and docs

- [x] `.claude/commands/run-tests.md` runs `bash tests/run-tests.sh --changed` by default, and runs
      the full suite when its arguments include `--all` or `--full`.
- [x] AGENTS.md "Agent Validation Steps" says to use `--changed` while iterating and to run the full
      suite (no `--changed`) before reporting a task done.
- [x] `docs/testing.md` documents `# COVERS:`, `tests/coverage-exclude`, `--changed` (rules A–H),
      `--list`, `CHANGED_FILES`, `test-lint.sh`, and the working-tree mount, and removes the
      "kept in sync" helper guidance.
- [x] The full suite (`bash tests/run-tests.sh`, default mode) passes locally and in every Docker
      image registered in `tests/.testenv`.

## Out of Scope

- Windows (`setup/setup.ps1`, `windows/*.ps1`) and Python helpers (`bin/heic2jpg.py`,
  `vscode/install-vscode-local-extension-to-vscodium.py`): add to `coverage-exclude`.
- macOS-GUI-only scripts (`osx/alfred.sh`, `osx/XBarPlugins/*`, `osx/configure_osx*.sh` beyond
  existing startup coverage): add to `coverage-exclude` unless a function can be unit tested
  cheaply.
- Line/branch coverage instrumentation (kcov/bashcov). The map is file-level only.
- CI (GitHub Actions) integration. The suite stays local-first.
- Adding a macOS Docker target.

## Edge Cases / Test Scenarios

- Mounting the repo into the container: `$HOME` symlinks created at build time point into
  `/home/test/dotfiles`. If the mount replaces that path, anything that writes inside the dotfiles
  tree at runtime (e.g. `vim/.vim/{undo,swaps,backups,sessions}`) must still work. Mount
  read-write, or mount elsewhere and point `DOTDIR` at the mount, and state which choice was made.
- Renamed/deleted files in `git diff` (`--changed` must handle `R`/`D` statuses; a deleted
  covered file should still select its tests so they fail loudly).
- Paths with spaces in the changed-file list.
- `--changed` run outside a git repo, or with an unknown ref: clear error, non-zero exit.
- A glob in `COVERS` (`sh/*.sh`) vs an exact path. `**` must match nested paths.
- A test with both `REQUIRES` and `COVERS` whose requirement is missing locally but present in
  Docker: skipped locally, run in Docker.
- zsh-only files (`zsh/*.sh`) must be linted with `zsh -n`, not `bash -n`/shellcheck.
- Sourcing `sh/*.sh` in tests must not depend on interactive-shell state. Stub or skip functions
  that need a TTY, the network, or macOS-only commands.
- `marks.sh` `unmark` uses `rm -i`: feed `y` on stdin in the test. Don't alias `rm` around it.
- `mkd` ends with `|| exit`: always call it in a subshell so a failure doesn't kill the test.
- Linux vs macOS `stat` in `tmux-status-ip.sh`: set the cache mtime with `touch -t`, which is portable.
- The currently staged work (`bin/worktrees.sh`, `test-worktrees.sh`, `sh/setenv.sh`,
  `sh/system.sh`) must be covered by the map.


## Assumptions

- Phase 4 scope (resolves the conflict between the old criterion and the old assumption): the
  acceptance criterion wins because it matches the user's stated goal of covering non-setup
  scripts. Phase 4 items 1–4 are required for this task. Items 5–7 may be deferred by listing the
  scripts in `coverage-exclude` as `TODO: test (follow-up)`. The earlier "may land Phase 4 as
  follow-up" assumption is withdrawn.
- A sufficient test means one assertion per bullet in the Phase 4 criteria above. It doesn't mean
  every function in a file. Functions that need a TTY, fzf, an editor, the network, `sudo`, or
  macOS-only tools (`img2base64`, `font_base64`, `getcertnames`, `mac_lookup`, `ssh_copy_id`,
  `update_os`, `man`, `tre`, `help`, `server`, `phpserver`, `em*`, `cdm`, `bat_theme_picker`) are
  only checked for being defined.
- zsh coverage is required only for `helpers.sh`, `path.sh`, and `marks.sh`. For other `sh/` files,
  the existing zsh startup test is enough to show they load under zsh.
- Adding main guards to `bin/tmux-status-*.sh`, `vscode/configure_vscode.sh`, and
  `osx/configure_browsers.sh` is in scope. It must not change their behaviour when executed directly.
- `claude-code-docker.sh` is tested by running it as a subprocess with stubs on `PATH`. It is not
  refactored into a sourceable form.
- The `--changed` default base is `HEAD`, so it covers uncommitted work. Branch comparison uses an
  explicit `--changed master`.
- `test-lint.sh` has `# COVERS:` entries for all tracked `*.sh`/`*.zsh` files, so it is selected
  whenever any script changes.
- The runner exports `CHANGED_FILES` only in `--changed` mode.
- Self-tests for the `--changed` selector live in a new `tests/test-cases/test-run-tests-selection.sh`
  (`# COVERS: tests/run-tests.sh`). They call `--list` against a temp git repo or a
  `CHANGED_FILES_OVERRIDE` env var, which the runner honours for testing only.
- The repo mount uses the path `/home/test/dotfiles`, read-write, so `$HOME` symlinks created at
  image build time resolve to the working tree. If that breaks a test, the implementer mounts
  elsewhere, sets `DOTDIR`, and records the choice in Implementation Notes.

## Implementation Notes

- **Docker mount is read-only** (`-v repo:/home/test/dotfiles:ro`), not read-write as assumed: no test needs to write into the repo, and ro protects the host tree. The mount initially hid the image's git-ignored setup output (`vim/.vim/autoload/`, `vim/.vim/plugins/`), which made `test-vim-configure.sh` fail on fresh-clone hosts (found by /code-review). Those dirs are now overlaid with anonymous volumes seeded from the image. I verified this against a tracked-files-only copy of the repo: the test fails without the overlay and passes with it.
- **Meta tests**: a `# COVERAGE: meta` header marks tests whose `COVERS` select them but do not count as coverage (`test-lint.sh`, `test-coverage-map.sh`). Without it, lint's `**/*.sh` would make every script "covered" and rule E would never fire. `tests/` paths are never matched against `COVERS`; they are handled by rules A–C only (so rule A selects exactly the changed test file).
- `create-test-envs.sh --print-setup-files` is the single source of truth for rule D. `tests/coverage-lib.sh` and `tests/docker/*` are also treated as runner infrastructure (rule B).
- `--list` does not run `create-test-envs.sh`, and neither does a run that selects nothing (e.g. docs-only changes exit in ~1s).
- **Real bugs the new tests exposed and fixed:**
  - `run-tests.sh`: Docker REQUIRES check used `${requires// / && command -v }`. In bash ≥ 5.2, `&` in the replacement means "matched text", so multi-word REQUIRES were broken. This is the "known issue" `test-remote-configure.sh` works around. Replaced with a loop.
  - `setup/configure_locale.sh` (Arch): `locale-gen` takes no arguments, so en_US.UTF-8 was never generated and every Arch shell warned about `LC_ALL`. It now uncomments the locale in `/etc/locale.gen` and runs `locale-gen` when the locale is missing.
  - Minimal Debian profile lacked the `locales` package, which caused the `test-remote-configure.sh` Debian failure that predates this task. Added it to `packages_pm_minimal_debian_1.txt` and regenerated.
  - `sh/marks.sh` overwrote any preset `MARKPATH` (now `${MARKPATH:-$HOME/.marks}`) and failed under zsh `set -u` (`$BASH_VERSION`). `sh/edits.sh` failed under `set -u` (`$SSH_TTY`). `sh/setenv.sh` returned 1 on Linux (trailing `$_is_osx && ...`). A `true` line was appended rather than rewriting that line, to avoid a conflict with the stashed worktrees change to the same spot.
  - `bin/tmux-status-ip.sh` `get_external_ip` returned 1 when every lookup failed with no cache. It now returns 0.
- `tests/testlib.sh` runs `set +o noclobber`: Docker runs tests via `bash -li`, which loads the interactive `noclobber` option and broke tests that truncate temp files. This is the single fix; the configure scripts were not changed for it.
- `configure_browsers.sh` restructure: preference strings stay top-level constants, and all side effects moved into `main()`. The user.js strings are not re-indented, so the written files are unchanged.
- `test-sh-libs.sh` runs children with an isolated `HOME`. An early draft ran before the `MARKPATH` fix and briefly created (then emptied) the real `~/.marks`, which I removed.
- `jdiff` exit-code assertions hide `difft`/diff prettifiers via a `_has` override, because difftastic exits 0 even when files differ.
- The worktrees work (`bin/worktrees.sh`, `test-worktrees.sh`) is currently in `stash@{0}` and not in the tree. After popping it, `test-worktrees.sh` needs a `# COVERS: bin/worktrees.sh` header, or `test-coverage-map.sh` will fail.
- /simplify pass: testlib gained `check`/`check_not`/`assert_contains`/`run_capture`/`write_stub` (replacing hand-rolled `&& ok || fail` and stub boilerplate); coverage-lib caches compiled glob regexes and owns `cov_tracked_files`; `REQUIRES` is parsed via `cov_get_header` (first 15 lines); lint runs shellcheck in parallel. test-coverage-map 4s→0.8s, test-lint 28s→3.5s, test-run-tests-selection 33s→10s.
- Final full run: 38 passed, 0 failed (local + Arch Docker; remote images via `test-remote-configure.sh`).
