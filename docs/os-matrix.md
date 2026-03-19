# OS Matrix (macOS vs Linux vs Windows)

## macOS (OSX, Darwin)
- Setup: `osx/configure_osx.sh`
- Package manager: Homebrew (brew)
- Common pitfalls:
  - Xcode CLI required for builds (handled by osx script).
  - Paths often differ from Linux; prefer `command -v` checks.
- Symlinks:
  - `osx/` dotfiles may be symlinked into `$HOME` (in addition to `misc/`).

## Linux — Debian/Ubuntu
- Setup: `linux/configure_packages_debian.sh`
- Package manager: `apt-get`
- Notes:
  - Installs a large baseline toolset.
  - Some tools may be older in apt; repo uses source install for fzf and conditional install logic for Starship.

## Linux — Arch
- Setup: `linux/configure_packages_arch.sh`
- Package managers:
  - `pacman`
  - Some installs via AUR helper `yay`
- Notes:
  - Similar baseline to Debian but with Arch names and AUR usage

## Linux — Minimal profile (remote VMs)
- Setup: `linux/configure_packages_minimal_debian.sh` (Debian) / `linux/configure_packages_minimal_arch.sh` (Arch) — auto-generated
- Entry point: `setup/setup-remote-vm.sh` (on-VM); `setup/deploy-remote-vm.sh` (local orchestrator)
- Shell: bash only (no zsh, no oh-my-zsh, no Starship)
- Notes:
  - Minimal package set — see `linux/packages_pm_minimal_*.txt` for the authoritative list
  - No git identity, no vim plugins, no language toolchains (Python, Node, Go)
  - Deployed via rsync + SSH; no git repo on the remote VM — `DOT_PULL_DOTFILES` is not used
  - Debian: `bat` installed as `batcat`, `fd-find` as `fdfind`; symlinks created in `~/bin` by `setup-remote-vm.sh`

## Windows
- Setup: `setup/setup.ps1`
- `windows/SetEnv.ps1` (shell environment)
- Package manager: Chocolatey
- Notes:
  - Script expects admin/elevated prompt for symlinks/system settings.
  - PowerShell `$PROFILE` is modified to source `SetEnv.ps1`.
  - VS DevCmd environment detection is implemented for VS 2012–2019 patterns.
