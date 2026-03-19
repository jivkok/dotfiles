# Task: Add support for "Minimal" VM Setup

**Status**: done
**Priority**: medium
**Created**: 2026-03-15

## Description

Add support for "minimal" VM setup.

The current dotfiles setup is designed for "full" machines - full-blown developer workstations with all tools, shell customizations, plugins, and language toolchains.
The new requirement is to support "minimal" VMs: minimal, disposable VMs that need only a core set of CLI tools and basic configuration, without the heavy personalization layers.

### General requirements
- Two scripts handle the minimal workflow:
  - `setup/setup-remote-vm.sh` — on-VM entrypoint for the minimal profile (analogous to `setup.sh` for the full profile). Runs directly on the target Linux system.
  - `setup/deploy-remote-vm.sh <user@host>` — local orchestrator. Rsyncs the necessary dotfiles subset to the remote host, then invokes `setup-remote-vm.sh` via SSH.
- Each profile defines which configure scripts are executed during setup
- Remote VM is controlled via SSH. It is assumed the SSH setup is already complete before `deploy-remote-vm.sh` is invoked.

### Minimal profile

Summary:

- Core CLI packages (described below)
- Shell profile setup: bash, no zsh; sourcing the sh/ and bash/ library
- Locale configuration (`setup/configure_locale.sh`)
- Home symlinks (`setup/configure_home_symlinks.sh`) — include for any symlinks relevant to the minimal profile
- tmux configuration

Detailed folders/files structure to include:

- `bash/`: all except `starship.toml`
- `bin/`: only `tmux-status-ip.sh`
- `linux/`: only the relevant generated config files
- `setup/`: `setup-remote-vm.sh`, `deploy-remote-vm.sh`, and other referenced setup scripts
- `sh/`: all
- `tmux/`: all

Packages to include:

```
# Common
bat
curl
eza
git
jq
mosh
ranger
ripgrep
tmux
vim

# Common - diagnostics
htop
lsof
strace

# Debian - apt
fd-find

# Arch - pacman
fd
```

Note: anything that is not explicitly mentioned in this section, is **not** included.

### Package lists
- Add `linux/packages_pm_minimal_1.txt` with the common minimal package set (all packages except `fd`/`fd-find`)
- Add `linux/packages_pm_minimal_debian_1.txt` with Debian-specific minimal packages (`fd-find`)
- Add `linux/packages_pm_minimal_arch_1.txt` with Arch-specific minimal packages (`fd`)
- Update `linux/generate_distro_package_setup_code.sh` to auto-detect `packages_pm_minimal_*.txt` source files and emit `configure_packages_minimal_debian.sh` and `configure_packages_minimal_arch.sh` (no-arg invocation generates all profiles)

### Testing
- Testing should cover both Debian/Ubuntu and Arch Linux distros.
- For testing needs, the remote VMs are available as Docker containers
- `tests/create-test-envs.sh` creates two more Docker test envs: for Debian and Arch. Naming convention: add `-remote` to the image name. Using the appropriate criteria for identifying whether an image needs to be re-generated.
- Minimal Docker test images use two new Dockerfiles (`tests/docker/Dockerfile.ubuntu-remote` and `tests/docker/Dockerfile.arch-remote`). These images are prepared for password-less SSH access from the current host (host public key baked in at build time via build arg). No copying of setup files occurs during these container builds.
- Add `tests/test-cases/test-remote-configure.sh` that:
  - Invokes `deploy-remote-vm.sh` pointing to the minimal Docker container (tests the full SSH deployment path)
  - Asserts that core tools are present
  - Asserts that heavy tools (node, pipx, oh-my-zsh) are NOT installed by this profile

### Implementation constraints
- All scripts must follow existing conventions: `#!/usr/bin/env bash`, `dot_trace`/`dot_error` logging, idempotent, OS-aware
- Do not break the default invocation of `setup/setup.sh`
- Linux package scripts are auto-generated - never edit them directly; regenerate via the code-generation script
- Neither `setup-remote-vm.sh` nor `deploy-remote-vm.sh` must reference `DOT_PULL_DOTFILES` or call `pull_latest_dotfiles`. The dotfiles are rsync'd to the VM by `deploy-remote-vm.sh`; there is no git repo on the remote VM. Unlike `setup.sh`, there is nothing to pull. This applies to both scripts — including env vars passed via SSH in `deploy-remote-vm.sh`.
- `setup-remote-vm.sh` and `deploy-remote-vm.sh` must be **excluded** from the full image hash computation in `tests/create-test-envs.sh`. These files are minimal-only; including them would cause unnecessary full image rebuilds when minimal scripts change.

---

## Acceptance Criteria

- [x] `setup/setup-remote-vm.sh` exists, is executable (`chmod 755`), and exits with 0 when run on a fresh Debian-based Linux system with `DOT_RELOAD_SHELL=0`
- [x] `setup/setup-remote-vm.sh` exits with 0 when run on a fresh Arch Linux system with `DOT_RELOAD_SHELL=0`
- [x] Neither `setup/setup-remote-vm.sh` nor `setup/deploy-remote-vm.sh` references `DOT_PULL_DOTFILES` or calls `pull_latest_dotfiles`
- [x] After minimal setup, all commands from the **minimal required packages** reference are available on `PATH` — verified on both Debian and Arch Docker images
- [x] After minimal setup, `~/.bash_profile` and `~/.bashrc` exist and contain content from `bash/.bash_profile` and `bash/.bashrc`, respectively. `~/.zshrc` is NOT written or modified by the minimal setup
- [x] After minimal setup, `~/.tmux.conf` is a symlink pointing to the dotfiles `tmux/.tmux.conf`
- [x] `linux/packages_pm_minimal_1.txt`, `linux/packages_pm_minimal_debian_1.txt`, and `linux/packages_pm_minimal_arch_1.txt` exist and together contain exactly the packages listed in the "Packages to include" reference
- [x] Running `linux/generate_distro_package_setup_code.sh` (no args) produces `linux/configure_packages_minimal_debian.sh` and `linux/configure_packages_minimal_arch.sh`, each starting with `# DO NOT EDIT — generated by generate_distro_package_setup_code.sh`
- [x] `tests/create-test-envs.sh` creates the two new "remote" minimal envs.
- [x] `tests/test-cases/test-remote-configure.sh` exists and passes against both the Debian and Arch Docker minimal images, asserting the **minimal required packages** are present and the **minimal excluded tools** are absent
- [x] `setup/setup.sh` (no-arg) continues to exit 0 and the full existing test suite passes with no regressions
- [x] Running `setup/setup-remote-vm.sh` twice on the same system exits 0 both times (idempotent)

## Out of Scope

- zsh setup, oh-my-zsh, Starship prompt, fzf — explicitly excluded from the minimal profile
- Python, Node.js, Go toolchains
- Vim plugins and `configure_vim.sh` — vim binary is installed via packages; `configure_vim.sh` is not called in the minimal profile
- `configure_git.sh` — not called; git binary is installed but no global git identity is configured
- Docker, dotnet, VSCode optional components
- macOS support — minimal VMs are Linux-only; `setup-remote-vm.sh` exits with an error on non-Linux systems
- SSH setup — assumed complete before `setup-remote-vm.sh` is invoked
- tmux plugin installation verification in tests — plugin git-cloning requires internet access at test time; test only asserts that `~/.tmux.conf` symlink is in place, not that plugins are downloaded

## Edge Cases / Test Scenarios

- **Idempotency**: Running `setup-remote-vm.sh` twice on a Debian container exits 0 both times with no errors
- **bash-only shell profiles**: `~/.bash_profile` and `~/.bashrc` are populated; `~/.zshrc` is either absent or unchanged from before the minimal setup ran
- **Generated scripts carry DO-NOT-EDIT header**: `configure_packages_minimal_debian.sh` and `configure_packages_minimal_arch.sh` each start with `# DO NOT EDIT — generated by generate_distro_package_setup_code.sh`

## Assumptions

- `configure_locale.sh` is included in the minimal setup as-is — it is already idempotent and side-effect-free.

## Implementation Notes

- `setup/setup-remote-vm.sh`: Linux-only entrypoint for the minimal profile; detects apt-get/pacman and invokes the appropriate generated minimal configure script; sets up bash profiles, bin symlinks (including batcat→bat and fdfind→fd aliases on Debian), misc dotfiles, locale, and tmux symlink.
- `setup/deploy-remote-vm.sh`: Rsyncs a curated subset of the repo (bash/, bin/tmux-status-ip.sh, linux/minimal scripts, setup/, sh/, tmux/) to the remote host, then SSHes to invoke setup-remote-vm.sh. Supports `-p port` for non-default SSH ports.
- `linux/generate_distro_package_setup_code.sh`: Extended with `generate_minimal_for_distro()` which auto-detects `packages_pm_minimal_*.txt` source files and emits `configure_packages_minimal_{debian,arch}.sh`.
- `tests/create-test-envs.sh`: Added remote OS tracking (DEBIAN_REMOTE, ARCH_REMOTE) with separate hash computation, and builds remote SSH-server images using `build-image-remote.sh`. Remote images use `_MINIMAL_IMAGE` key suffix to avoid being picked up as standard test environments by `run-tests.sh`.
- `tests/test-cases/test-remote-configure.sh`: Deploys minimal setup to both Debian and Arch remote containers, verifies all required packages are present, excluded tools are absent, bash profiles are set up correctly, tmux symlink exists, and the setup is idempotent. Uses a `_HAVE_DEPS` guard instead of `exit 0` to avoid a bash login-shell logout-script edge case with `set -e` on Debian.
