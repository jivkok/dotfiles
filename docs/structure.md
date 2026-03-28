# Repo Structure

## Top-level layout
- `setup/` — orchestration and shared helpers (authoritative)
- `sh/` — shell environment library, sourced at shell startup via `sh/setenv.sh`. Includes paths, env exports, common aliases and functions
- `osx/` — macOS-specific dotfiles and macOS setup script(s)
- `linux/` — distro-specific package install scripts (Debian/Arch)
- `windows/` — PowerShell environment + Windows-specific config
- `misc/` — dotfiles symlinked into `$HOME` (files starting with `.`)
- `{docker, dotnet, fzf, git, go, nodejs, python, vim, tmux, zsh}/` — component-specific configuration and installers

## How it works (high level)

### Setup

#### Unix (macOS/Linux) — "full" profile
Primary orchestrator:
- `setup/setup.sh`

Flow:
1) Detect OS and applicable OS package script:
   - Debian/Ubuntu: `linux/configure_packages_debian.sh`
   - Arch: `linux/configure_packages_arch.sh`
   - macOS: `osx/configure_osx.sh`
2) Configure OS:
   - shell profiles (Bash, ZSH)
   - symlinks to misc config files (in `misc/`, `osx/`) into `$HOME`
   - configure components: `git/`, `python/`, `vim/`, `zsh/`, `tmux/`, `fzf/`, etc.

#### Linux remote VMs — "minimal" profile
Two scripts handle the minimal workflow:
- `setup/setup-remote-vm.sh` — on-VM entrypoint. Runs directly on the target Linux system (Linux-only; exits with error on macOS). Installs the minimal package set, sets up bash profiles (no zsh), home symlinks, locale, and tmux config.
- `setup/deploy-remote-vm.sh <user@host>` — local orchestrator. Rsyncs the minimal-relevant dotfiles subset to the remote host, then invokes `setup-remote-vm.sh` via SSH. Supports `-p <port>` for non-default SSH ports.

Minimal package scripts: `linux/configure_packages_minimal_debian.sh` and `linux/configure_packages_minimal_arch.sh` (auto-generated — see `docs/development.md`).

**Full vs minimal profile comparison:**

| Component | Full profile | Minimal profile |
|-----------|:------------:|:---------------:|
| Bash profile | ✓ | ✓ |
| ZSH + oh-my-zsh + Starship | ✓ | ✗ |
| Git config/identity | ✓ | ✗ |
| Vim + plugins | ✓ | ✗ |
| Tmux | ✓ (config + plugins) | ✓ (config only) |
| FZF | ✓ | ✗ |
| Python toolchain | ✓ | ✗ |
| Node.js | ✓ | ✗ |
| Go tools | ✓ | ✗ |
| Home symlinks (`misc/`) | ✓ | ✓ |
| Locale setup | ✓ | ✓ |
| Home bin (full) | ✓ | bat/fd symlinks only |
| `git pull` on run | ✓ (`DOT_PULL_DOTFILES=1`) | ✗ (rsync, no repo on VM) |
| Supported OS | macOS, Linux | Linux only |

#### Windows
Primary orchestrator: `setup/setup.ps1`

Flow:
- Install Chocolatey + packages
- Clone/pull dotfiles
- Ensure PowerShell `$PROFILE` sources `windows/SetEnv.ps1`
- Create shortcuts and apply a few system tweaks

### Shell environment bootstrapping

Bash: `bash/.bashrc`, `bash/_bash_profile`;
ZSH: `zsh/.zshrc`
Powershell: `windows/SetEnv.ps1`
DOS: `windows/SetEnv.cmd`


## Orchestration invariants

1. There are two Unix entry points:
- `setup/setup.sh` — full profile (full developer workstation). OS selection and component invocation happen here.
- `setup/setup-remote-vm.sh` — minimal profile (minimal Linux VM). Invoked remotely by `setup/deploy-remote-vm.sh`.
- Both scripts should stay readable and “glue-only”.

2. Shared helpers live in `setup/setup_functions.sh` - All scripts should source it (directly or indirectly) if they want:
- logging (`dot_trace`, `dot_error`)
- symlink helpers (with backup behavior)
- `append_or_merge_file` (no duplication)
- clone/pull helper for external repos

3. Shell profiles are merged, not replaced
- `setup/configure_shell_profiles.sh` merges bootstrap snippets into:
  - `~/.bash_profile`, `~/.bashrc`, `~/.zshrc`
- Do not switch this to a symlink approach unless you redesign the repo’s “local customization” story.

4. Home symlinks are restricted to dotfiles
- `setup/configure_home_symlinks.sh` links `misc/.*` into `$HOME`.
- Keep `misc/` limited to files that are safe to globally link.

5. Component scripts should be runnable in isolation
- Each `*/configure_*.sh` should:
  - detect OS
  - install dependencies
  - link or merge configs
  - exit cleanly if unsupported

## Where to add things
- New OS-only setup? Put it in `osx/`, `linux/`, or `windows/` and call it from orchestrator.
- New cross-platform component? Create `toolname/configure_toolname.sh` and invoke it from `setup/setup.sh`.
- New global dotfile? Add to `misc/` (only if it’s a `.*` file intended for `$HOME`).
