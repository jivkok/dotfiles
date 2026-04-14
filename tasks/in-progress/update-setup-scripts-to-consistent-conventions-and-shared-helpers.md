# Task: Update setup/configure scripts to use consistent conventions and shared helpers

**Status**: in-progress
**Priority**: medium
**Created**: 2026-04-13

## Overview

Update all in-scope setup and tool configure scripts to use consistent conventions and
shared helpers defined in `setup/setup_functions.sh` and `sh/helpers.sh`. The goal is to
eliminate duplicated logic, enforce uniform logging, package management, OS detection, file download, and backup patterns across the entire dotfiles setup system.

## Scope

**In scope:**
- All `configure_*.sh` scripts for individual tools (e.g. `configure_vim.sh`, `configure_git.sh`)
- Setup scripts under `setup/`, `linux/`, `osx/`

**Out of scope:**
- Any script that is not a `configure_*.sh` file and is not a setup script under `setup/`, `linux/`, or `osx/`

## Script Categories

Scripts fall into two categories based on how they handle packages:

- **Bulk setup scripts** (`configure_osx_packages.sh`, `configure_packages_arch.sh`,
  `configure_packages_debian.sh`, `configure_packages_minimal_arch.sh`,
  `configure_packages_minimal_debian.sh`): first upgrade all existing packages globally
  (e.g. `brew upgrade`, `pacman -Syu`), then install missing packages without per-package
  upgrade checks. Use `install_*` helpers.
- **Tool configure scripts** (all other `configure_*.sh`): install or upgrade individual
  packages as part of tool setup. Use `install_or_upgrade_*` helpers.

## Conventions

### Package Management

- Bulk setup scripts call the global upgrade command (e.g. `brew upgrade`, `pacman -Syu`)
  before any `install_*` calls; per-package upgrade checks are therefore unnecessary.
- Tool configure scripts use `install_or_upgrade_*` helpers for every package operation.
- No in-scope script calls `brew install`, `apt-get install`, `pacman -S`, or `yay -S`
  directly for individual packages.
- All package helpers are idempotent:
  - `install_*`: no-op if the package is already installed; returns 1.
  - `install_or_upgrade_*`: installs if absent, upgrades if an upgrade is available.
- Scripts may not define their own package install/upgrade logic. Script-local helpers
  for functionality not covered by any shared category are permitted.

### Logging

Log levels (numeric; lower = more severe):

| Level | Function      | When to use |
|-------|---------------|-------------|
| 0     | `log_error`   | Actual error conditions |
| 1     | `log_warning` | Recoverable or expected-but-notable conditions (tool not found so a step is skipped, version mismatch handled gracefully). Orange foreground. |
| 2     | `log_info`    | Start/end of each major tool configure script (`"Configuring X ..."` / `"Configuring X done."`); major phase delimiters in setup scripts (e.g. `"Installing brew packages."`). |
| 3     | `log_trace`   | Individual fine-grained steps: single symlink, single file merge, single package check, skip-on-wrong-OS notice. |

- `LOG_LEVEL` env var (default: `2` / info) controls which messages are emitted; a message
  is printed only if its numeric level ≤ `LOG_LEVEL`.
- `LOG_LEVEL` can be overridden before invoking any script
  (e.g. `LOG_LEVEL=3 bash setup/setup.sh` for full trace, `LOG_LEVEL=0` for errors only).
- No in-scope script uses `echo` or `printf` for user-facing messages. All output goes
  through `log_*` helpers. (`echo`/`printf` that write content into files are exempt.)

### OS and Command Detection

- OS branching uses `_is_osx`, `_is_linux`, `_is_arch`, or `_is_debian` (from `sh/helpers.sh`). No inline `uname -s`.
- Command-presence checks use `_has`. No inline `command -v`.

### File Operations

- All file downloads use `download_file`. No inline `curl` or `wget` for downloads.
- All timestamped backups use `backup_file_if_exists` or `backup_folder_if_exists`. No
  inline backup logic.
- `download_file`: downloads to a temp file, then moves atomically to destination (skips
  the move if temp path equals destination path).
- Backup helpers: timestamp format `YYYY-MM-DD_HH-MM-SS`; if two backups land in the same
  second a counter suffix is appended.

### Git Repos

- Simple clone-or-pull operations use `clone_or_update_repo`.
- Scripts with multi-step git operations beyond a simple clone or pull (e.g.
  `fzf/configure_fzf.sh` with its `run_install` tracking flag) may keep their own
  implementation.

## Helpers Reference

All helpers live in `setup/setup_functions.sh`, except OS/command detection which is in
`sh/helpers.sh` and sourced automatically.

**Package install-only** (bulk scripts):

| Helper | Package manager | Presence check |
|--------|----------------|----------------|
| `install_brew_package <pkg> [args...]` | `brew install` | `brew list --versions` |
| `install_cask_package <pkg> [args...]` | `brew install --cask` | `brew list --versions --cask` |
| `install_apt_package <pkg> [args...]` | `apt-get install` | `dpkg -s` |
| `install_pacman_package <pkg> [args...]` | `pacman -S` | `pacman -Q` |
| `install_yay_package <pkg> [args...]` | `yay -S` | `yay -Q` |

**Package install-or-upgrade** (tool configure scripts):

| Helper | Package manager |
|--------|----------------|
| `install_or_upgrade_brew_package <pkg> [args...]` | brew |
| `install_or_upgrade_cask_package <pkg> [args...]` | brew cask |
| `install_or_upgrade_apt_package <pkg> [args...]` | apt-get |
| `install_or_upgrade_pacman_package <pkg> [args...]` | pacman |
| `install_or_upgrade_yay_package <pkg> [args...]` | yay |

All install/install-or-upgrade helpers: first arg = package name, remaining args passed
through to the package manager. Return codes: `0` = installed/upgraded, `1` = already
present/up-to-date, `2` = error.

**File operations:**

| Helper | Description |
|--------|-------------|
| `download_file <url> <dest_path> [curl_args...]` | Download via curl to temp, move to dest |
| `backup_file_if_exists <path>` | Timestamped copy of a file; no-op if absent |
| `backup_folder_if_exists <path>` | Timestamped copy of a directory; no-op if absent |

**OS / command detection** (from `sh/helpers.sh`, available after sourcing `setup_functions.sh`):

| Symbol | Meaning |
|--------|---------|
| `_OS` | Raw `uname -s` value |
| `_is_osx` | `true` on macOS |
| `_is_linux` | `true` on Linux |
| `_is_arch` | `true` on Arch Linux |
| `_is_debian` | `true` on Debian/Ubuntu |
| `_has <cmd>` | Returns 0 if command is in PATH |

**Other:**

| Helper | Description |
|--------|-------------|
| `clone_or_update_repo <url> <dir>` | Clone if absent, pull if present |
| `make_symlink <src> <target_dir> [name]` | Symlink with timestamped backup on conflict |
| `make_dotfiles_symlinks <src_dir> <target_dir>` | Symlink all dotfiles in a directory |
| `append_or_merge_file <src> <target>` | Append missing lines from src into target |

## Acceptance Criteria

**Helpers — package management:**
- [x] `install_brew_package`, `install_cask_package`, `install_apt_package`, `install_pacman_package`, `install_yay_package` exist in `setup/setup_functions.sh` with correct presence checks and return codes.
- [x] `install_or_upgrade_apt_package`, `install_or_upgrade_pacman_package`, `install_or_upgrade_yay_package` exist in `setup/setup_functions.sh`; install if absent, upgrade if available, idempotent.

**Helpers — logging:**
- [x] `log_warning` exists in `setup/setup_functions.sh` with orange foreground (`tput setaf 3`).
- [x] Each log function (`log_error`, `log_warning`, `log_info`, `log_trace`) checks `LOG_LEVEL` before emitting; prints only if its numeric level ≤ `LOG_LEVEL`.
- [x] `LOG_LEVEL` defaults to `2` (info) and is documented as an overridable env var in `setup_functions.sh`.

**Helpers — file operations:**
- [x] `download_file <url> <dest_path>` exists: downloads to temp, moves atomically to dest (skips move if paths are equal).
- [x] `backup_file_if_exists <path>` exists: timestamped copy; no-op if absent; counter suffix on same-second collision.
- [x] `backup_folder_if_exists <path>` exists: same as above for directories.

**`sh/helpers.sh` integration:**
- [x] `setup/setup_functions.sh` sources `sh/helpers.sh` so `_has`, `_OS`, `_is_osx`, `_is_linux`, `_is_arch`, `_is_debian` are available to all scripts that source `setup_functions.sh`.

**In-scope scripts — package management:**
- [x] No bulk setup script calls a package manager directly for individual packages. Global upgrade commands are called directly; per-package installs go through `install_*` helpers.
- [x] No tool configure script calls a package manager directly. All package operations go through `install_or_upgrade_*` helpers.

**In-scope scripts — logging:**
- [ ] No in-scope script uses `echo` or `printf` for user-facing messages. All output uses `log_*` helpers. (`echo`/`printf` writing file content is exempt.)
- [ ] Each tool configure script opens with `log_info "Configuring <Tool> ..."` and closes with `log_info "Configuring <Tool> done."`.
- [ ] `log_info` delimits major phases in setup/bulk scripts (e.g. `"Installing brew packages."`).
- [ ] Individual steps use `log_trace`; recoverable skips use `log_warning`; errors use `log_error`.
- [ ] Generated `configure_packages_*.sh` scripts contain `log_info` opening/closing bookends and
  phase-delimiter `log_info` calls for each section (upgrade, common packages, distro-specific
  packages, AUR, Go tools, non-packaged software). These are emitted by
  `generate_distro_package_setup_code.sh` — fixing them requires updating the generator and
  re-running it (not editing the generated files directly).

**In-scope scripts — OS and command detection:**
- [x] No in-scope script uses `uname -s` inline. All OS detection uses `_is_*` helpers.
- [x] No in-scope script uses `command -v` directly. All presence checks use `_has`.

**In-scope scripts — file operations:**
- [x] No in-scope script calls `curl` or `wget` directly for downloads. All downloads use `download_file`.
- [x] No in-scope script implements its own timestamped backup logic. All backups use `backup_*_if_exists`.

**In-scope scripts — no inline shared helpers:**
- [x] No in-scope script defines a function duplicating a shared helper category. `setup/setup_functions.sh` is exempt.

**Tests:**
- [x] All existing tests pass without modification.
- [x] `tests/test-cases/test-setup-functions.sh` covers `LOG_LEVEL` filtering, `download_file`, `backup_file_if_exists`, `backup_folder_if_exists`, and `append_or_merge_file`.

## Edge Cases

**Package management:**
- Running any in-scope script twice produces no errors and no duplicate changes (idempotency).
- `install_apt_package` on an already-installed package: no-op, returns 1.
- `install_or_upgrade_apt_package` on a package already at latest version: exits cleanly, returns 1.
- `install_pacman_package`, `install_yay_package` and their `install_or_upgrade_*` counterparts behave analogously.

**File operations:**
- `download_file` when the destination directory does not exist: fails with a clear `log_error`; no partial file left at destination.
- `download_file` with an unreachable URL: temp file is cleaned up, `log_error` is called.
- `backup_file_if_exists` on a non-existent path: no-op, no error.
- `backup_file_if_exists` called twice within the same second: both backups are preserved via counter suffix.

**OS / script guards:**
- A configure script invoked on the wrong OS (e.g. an apt-only script on macOS): `_is_linux`/`_is_debian` guards prevent execution; `log_trace` indicates the skip.
- `fzf/configure_fzf.sh` retains its multi-step git handling (clone + `run_install` flag) under the complex-git exception.

## Assumptions

- The apt presence check uses `dpkg -s <pkg>`; applies to both `install_apt_package` and `install_or_upgrade_apt_package`.
- The pacman/yay presence checks use `pacman -Q <pkg>` / `yay -Q <pkg>`, mirroring how brew uses `brew list --versions`.
- Bulk setup scripts are responsible for calling the global upgrade command before their install loop; `install_*` helpers do not trigger upgrades themselves.
- `sh/helpers.sh` is sourced from `setup_functions.sh` using a path relative to `BASH_SOURCE`; `dotdir` is not required to be set before sourcing.
- `fzf/configure_fzf.sh` is the only current script that qualifies for the complex-git exception.
- `echo`/`printf` used to write content into files (e.g. appending to `/etc/shells`) are not logging and are not subject to the logging rule.
- The `log_info` open/close bookends apply to tool configure scripts. Setup/bulk scripts use `log_info` more loosely to mark major phases.

## Implementation Notes

Generated scripts (`configure_packages_*.sh`) are in scope for all conventions. Fixes to
their logging belong in `generate_distro_package_setup_code.sh`. After any generator change,
re-run `linux/generate_distro_package_setup_code.sh` to regenerate all four scripts.
