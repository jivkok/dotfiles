# Task: Complete the Configuration Scripts for Installing and Configuring VSCode/VSCodium

**Status**: done
**Priority**: medium
**Created**: 2026-03-01

## Description

Complete the configuration scripts for installing and configuring VSCode/VSCodium. Relevant scripts are in folder `vscode/` with entry point `configure_vscode.sh`.

The script currently has two `# TODO` placeholders for Linux VSCode installation (Debian and Arch paths in `install_vscode_and_dependencies`), and VSCodium installation is absent entirely for both Linux paths. The macOS path and all post-install logic (config deployment, extension installation, Python fallback helper) are already complete.

## Acceptance Criteria

**Installation — macOS (already implemented; must not regress)**
- [x] Running `configure_vscode.sh` on macOS installs VSCode via Homebrew cask if not already installed
- [x] Running `configure_vscode.sh` on macOS installs VSCodium via Homebrew cask if not already installed
- [x] Running `configure_vscode.sh` on macOS installs `jq` via Homebrew if not already installed

**Installation — Linux/Debian (to be implemented)**
- [x] Running `configure_vscode.sh` on Debian/Ubuntu installs VSCode via the official Microsoft apt repository if not already installed
- [x] Running `configure_vscode.sh` on Debian/Ubuntu installs VSCodium via the community apt repository (packages.vscodium.com) if not already installed
- [x] Running `configure_vscode.sh` on Debian/Ubuntu installs `jq` via `apt-get` (already present; must remain)

**Installation — Linux/Arch (to be implemented)**
- [x] Running `configure_vscode.sh` on Arch installs VSCode (`visual-studio-code-bin`) via `yay` if not already installed
- [x] Running `configure_vscode.sh` on Arch installs VSCodium (`vscodium-bin`) via `yay` if not already installed
- [x] Running `configure_vscode.sh` on Arch installs `jq` via `pacman` (already present; must remain)

**All platforms**
- [x] Re-running `configure_vscode.sh` on any platform skips installation of already-installed editors and dependencies without error (idempotent)
- [x] `settings.json` and `keybindings.json` are deployed to the correct OS-specific User directory for both `code` and `codium`: `~/.config/{Code,VSCodium}/User` on Linux, `~/Library/Application Support/{Code,VSCodium}/User` on macOS
- [x] If an OS-specific override file (e.g., `settings.linux.json`) exists, it is deep-merged with the base via `jq -s '.[0] * .[1]'`; otherwise the base file is copied directly
- [x] Any pre-existing config file at the destination is backed up with a timestamp suffix before being overwritten
- [x] Extensions in `extensions.txt` are installed into both `code` and `codium`; `extensions.code.txt` into `code` only; `extensions.codium.txt` into `codium` only
- [x] If `codium --install-extension` reports "Extension '…' not found", `install-vscode-local-extension-to-vscodium.py` is invoked as: `python3 <script> --extension <id> --code-bin code --vscode-dir ~/.vscode --vscodium-dir ~/.vscode-oss`
- [x] The script exits non-zero with a clear error message when run on an unsupported OS

**Python helper**
- [x] `install-vscode-local-extension-to-vscodium.py` accepts `--extension`, `--code-bin`, `--vscode-dir`, `--vscodium-dir` arguments, mirrors the extension directory from VS Code to VSCodium, updates VSCodium's `extensions.json`, and exits 0 on success

**Tests**
- [x] A test file `tests/test-cases/test-vscode-configure.sh` exists and is discovered by `tests/run-tests.sh`
- [x] The test file covers: config file deployment (with and without OS-specific override), extension list parsing (comments and blank lines stripped), and the `prepare_and_copy_vscode_config_files` skip conditions (empty destination dir, missing source file)
- [x] All tests pass locally and in the existing Docker environments (Ubuntu, Arch) via `bash tests/run-tests.sh`

## Out of Scope

- Windows support
- JSONC (JSON-with-comments) parsing
- Rollback on partial failure
- Changes to `extensions.txt`, `extensions.code.txt`, `extensions.codium.txt`, `settings.json`, or `keybindings.json`
- Configuring each editor independently (script always configures both)
- Integration tests that require VSCode or VSCodium binaries to actually be installed

## Edge Cases / Test Scenarios

- VSCode or VSCodium already installed on Linux — skip without error
- Config destination directory does not exist — `mkdir -p` must create it before writing
- No OS-specific override file present — base file is copied directly without merge
- `yay` not available on Arch — script must fail fast with a clear error message
- Microsoft or VSCodium apt repository already configured on Debian — adding it again must not error
- Extension file contains comment-only lines or blank lines — must be ignored (already handled; must not regress)
- Extension not on Open VSX — Python fallback helper invoked for VSCodium

## Assumptions

- "Complete" refers to: (1) the two `# TODO` placeholders for Linux VSCode installation in `install_vscode_and_dependencies`, and (2) missing VSCodium installation for both Linux distros
- Linux/Debian: VSCode installed by adding the official Microsoft apt repository; VSCodium by adding packages.vscodium.com apt repository
- Linux/Arch: VSCode (`visual-studio-code-bin`) and VSCodium (`vscodium-bin`) installed via `yay`, consistent with the AUR pattern in `linux/configure_packages_arch.sh`
- `install-vscode-local-extension-to-vscodium.py` is already fully implemented; the Python helper criterion is a verification of its existing interface, not new work
- Tests use mocked/stubbed commands rather than real VSCode/Codium binaries, consistent with the existing Docker-based test environments which do not have GUI apps installed
- macOS path is already complete and must not be modified

## Implementation Notes

- Fixed a pre-existing bug: `local settingsdir="${1}.json"` in `prepare_and_copy_vscode_config_files` appended `.json` to the directory path, causing all source-file existence checks to fail silently. Corrected to `local settingsdir="${1}"`.
- Fixed a pre-existing bug: Debian idempotency check used `apt list --installed >/dev/null 2>&1 | grep` — the `>/dev/null` discards stdout before the pipe, so grep always received empty input. Corrected to `2>/dev/null`.
- Added a `BASH_SOURCE` guard around the execution section of `configure_vscode.sh` so the file can be sourced (for testing or reuse) without running the main body.
- Test functions are defined in `tests/test-cases/helpers/vscode-functions.sh` (not sourced from `vscode/configure_vscode.sh`) because the Docker test environments bind-mount only `tests/`, not the full repo; sourcing from the Docker image's baked-in copy of configure_vscode.sh would use the pre-guard version and fail.
