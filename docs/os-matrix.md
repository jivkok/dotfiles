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

## Windows
- Setup: `setup/setup.ps1`
- `windows/SetEnv.ps1` (shell environment)
- Package manager: Chocolatey
- Notes:
  - Script expects admin/elevated prompt for symlinks/system settings.
  - PowerShell `$PROFILE` is modified to source `SetEnv.ps1`.
  - VS DevCmd environment detection is implemented for VS 2012–2019 patterns.
