# Dotfiles

Machine configuration scripts for macOS, Linux (Debian/Ubuntu, Arch), and Windows.

## Table of Contents

- [Dotfiles](#dotfiles)
  - [Table of Contents](#table-of-contents)
  - [What is included](#what-is-included)
    - [macOS / Linux](#macos--linux)
    - [Windows](#windows)
  - [macOS / Linux](#macos--linux-1)
    - [Installation](#installation)
    - [Optional tools](#optional-tools)
    - [Customization](#customization)
    - [Upgrade](#upgrade)
  - [Windows](#windows-1)
    - [Installation](#installation-1)
    - [Customization](#customization-1)
    - [Upgrade](#upgrade-1)
  - [Testing](#testing)
  - [Docs](#docs)
  - [Credits](#credits)

---

## What is included

### macOS / Linux

| Area | Details |
|------|---------|
| Shell | Bash and Zsh — options, prompt (Starship), aliases, functions (`sh/`) |
| Git | Config, aliases, global gitignore (`git/`) |
| Python | python3, pip, pipx + packages (`python/`) |
| Node.js | Node, npm, global packages (`nodejs/`) |
| Vim | Config and plugins (`vim/`) |
| Zsh | oh-my-zsh, plugins, theme (`zsh/`) |
| Tmux | Config and plugins (`tmux/`) |
| fzf | Fuzzy finder + shell integrations (`fzf/`) |
| VSCode | Settings, keybindings, extensions (`vscode/`) |

**Optional** (run separately — not part of the default setup):

| Tool | Script |
|------|--------|
| Docker | `docker/configure_docker.sh` |
| Go | `go/configure_go.sh` |
| .NET | `dotnet/configure_dotnet.sh` |

### Windows

* Chocolatey packages
* Command shell and PowerShell configuration
* Console setup

---

## macOS / Linux

### Installation

```sh
# macOS
cd $HOME
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git
git clone https://github.com/jivkok/dotfiles.git dotfiles
bash dotfiles/setup/setup.sh

# Linux (Debian/Ubuntu)
cd $HOME
sudo apt-get install -y git
git clone https://github.com/jivkok/dotfiles.git dotfiles
bash dotfiles/setup/setup.sh

# Linux (Arch)
cd $HOME
sudo pacman -S --noconfirm git
git clone https://github.com/jivkok/dotfiles.git dotfiles
bash dotfiles/setup/setup.sh
```

`setup.sh` auto-detects OS, installs packages, configures shell profiles, and sets up all included components. The shell is reloaded at the end.

### Optional tools

Tools not included in the default setup can be configured individually:
- Docker: `docker/configure_docker.sh`
- Go: `go/configure_go.sh`
- DotNet: `dotnet/configure_dotnet.sh`
- VSCode: `vscode/configure_vscode.sh`

### Customization

`setup/configure_shell_profiles.sh` **merges** bootstrap snippets into your existing `~/.bash_profile`, `~/.bashrc`, and `~/.zshrc` rather than replacing them. Any personal settings already in those files are preserved. Add machine-local overrides directly to those files after running setup.

### Upgrade

```sh
cd ~/dotfiles
git pull
bash setup/setup.sh
```

---

## Windows

### Installation

```bat
rem Command shell:
git clone https://github.com/jivkok/dotfiles.git %USERPROFILE%\dotfiles
@powershell -NoProfile -ExecutionPolicy Bypass -File %USERPROFILE%\dotfiles\setup\setup.ps1
```

```posh
# PowerShell:
git clone https://github.com/jivkok/dotfiles.git $HOME\dotfiles
. $HOME\dotfiles\setup\setup.ps1
```

### Customization

Create `%USERPROFILE%\profile.cmd` (Command shell) or `$Home\profile.ps1` (PowerShell) for local overrides. These are sourced at the end of the respective shell startup and can override any settings, functions, or aliases.

### Upgrade

```bat
rem Command shell:
cd /d %USERPROFILE%\dotfiles
git pull
```

```posh
# PowerShell:
cd $HOME\dotfiles
git pull
```

---

## Testing

The repo includes a test suite (`tests/run-tests.sh`) that runs locally and in Docker containers (Debian, Arch).

See [`docs/testing.md`](./docs/testing.md) for details.

---

## Docs

| File | Contents |
|------|----------|
| [`docs/structure.md`](./docs/structure.md) | Repo layout, setup flow, orchestration invariants, where to add things |
| [`docs/development.md`](./docs/development.md) | Development workflow and agent pipeline |
| [`docs/testing.md`](./docs/testing.md) | Test architecture, environments, Docker images, test categories, scripts reference |
| [`docs/coding-conventions.md`](./docs/coding-conventions.md) | Shell scripting conventions |

---

## Credits

* Mathias Bynens for his [dotfiles](https://github.com/mathiasbynens/dotfiles)
* Balaji Srinivasan for his [dotfiles](https://github.com/startup-class/dotfiles)
* Rob Reynolds for [Chocolatey.org](https://chocolatey.org/)
* Matt Wrock for [boxstarter.org](https://boxstarter.org/)
