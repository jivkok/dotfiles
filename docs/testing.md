# Testing

## Overview

Tests verify that the dotfiles setup produces a correctly configured environment. Every test runs in all applicable environments: locally on the host machine, and in Docker containers for each supported Linux OS.

---

## Target OSes

| ID | Description |
|----|-------------|
| `OSX` | macOS. Local only — not supported as a Docker target. |
| `DEBIAN` | Debian / Ubuntu and derivatives. Full profile. |
| `ARCH` | Arch Linux. Full profile. |
| `DEBIAN_REMOTE` | Debian / Ubuntu. Minimal profile. SSH-enabled Docker image only. |
| `ARCH_REMOTE` | Arch Linux. Minimal profile. SSH-enabled Docker image only. |

---

## Setup Files Per OS

The setup hash for each OS is computed from the combined content of its relevant setup files. If any of these files change, the environment for that OS must be rebuilt before tests run.

**Full profile (OSX / DEBIAN / ARCH):**

| OS | Files included in hash |
|----|------------------------|
| OSX, DEBIAN, ARCH | `setup/*.sh` excluding `setup-remote-vm.sh` and `deploy-remote-vm.sh`, plus component configure scripts invoked by `setup.sh` (`git`, `python`, `nodejs`, `vim`, `zsh`, `tmux`, `fzf`) |
| OSX | + `osx/configure_osx.sh` |
| DEBIAN | + `linux/configure_packages_debian.sh` |
| ARCH | + `linux/configure_packages_arch.sh` |

**Minimal profile (DEBIAN_REMOTE / ARCH_REMOTE):**

| OS | Files included in hash |
|----|------------------------|
| DEBIAN_REMOTE, ARCH_REMOTE | `setup/setup-remote-vm.sh`, `setup/setup_functions.sh`, `setup/configure_home_symlinks.sh`, `setup/configure_locale.sh`, the relevant Dockerfile |
| DEBIAN_REMOTE | + `linux/configure_packages_minimal_debian.sh` |
| ARCH_REMOTE | + `linux/configure_packages_minimal_arch.sh` |

---

## Workflow

### Step 1 — Create / update test environments

```bash
bash tests/create-test-envs.sh
```

This script:

1. Detects the host OS (`OSX`, `DEBIAN`, or `ARCH`).
2. Computes a SHA-256 hash (12 chars) of setup files for each target OS (full and minimal).
3. Compares current hashes against the last known hashes stored in `tests/.testenv`.
4. For each **full** OS whose hash has changed:
   - **Host OS**: runs `setup/setup.sh` locally (`DOT_PULL_DOTFILES=0 DOT_RELOAD_SHELL=0`).
   - **DEBIAN / ARCH** (non-host): builds a Docker image named `dotfiles-test-<os>-<hash>`. If an image with that name already exists, the build is skipped.
   - **OSX** (non-host): skipped — Docker target not supported.
5. For each **minimal** OS (`DEBIAN_REMOTE`, `ARCH_REMOTE`) whose hash has changed: builds an SSH-enabled Docker image named `dotfiles-test-<os>-remote-<hash>` using `build-image-remote.sh`. Requires a host SSH public key (auto-detected from `~/.ssh/id_ed25519.pub`, `id_rsa.pub`, or `id_ecdsa.pub`) which is baked into the image as a build arg. If no key is found the build is skipped with a warning.
6. Resolves the current Docker image name for each OS by checking which image exists for the current hash.
7. Writes updated state to `tests/.testenv`.

### Step 2 — Run tests

```bash
bash tests/run-tests.sh [--all | --filter <cmd>]
```

| Flag | Behaviour |
|------|-----------|
| _(none)_ | **Default.** Runs core tests and any optional tests whose required tools are installed. Tests with unmet requirements are skipped with a `SKIPPED:` notice. |
| `--all` | Runs every test unconditionally. Fails immediately if a required tool is missing. Use this for a full audit. |
| `--filter <cmd>` | Runs only tests that declare `<cmd>` in their `REQUIRES` header. Useful for verifying a specific optional tool after installing it. |

This script:

1. Discovers all test files matching `tests/test-cases/test-*.sh` (sorted).
2. Filters tests according to the flag and the `REQUIRES` header of each file (see [Test categories](#test-categories) below).
3. Runs selected tests locally first.
4. Reads `tests/.testenv` for `*_DOCKER_IMAGE` variables. Each non-empty value is a Docker image to test in.
5. For each Docker image, evaluates `REQUIRES` headers **inside the container** (using `bash -li` so the full PATH is available) and skips tests whose required tools are absent — independently of the local machine. In **default mode** all discovered tests are considered per container; in **filter/all mode** the already-filtered list is used. Tests run with `bash -li` so PATH and shell environment are fully initialised. The `tests/` directory is bind-mounted read-only into the container at `/home/test/dotfiles/tests`, so test file changes take effect without rebuilding the image.
6. Fails immediately on any test error.

---

## State file: `tests/.testenv`

Persists state between runs. Written by `create-test-envs.sh`, read by `run-tests.sh`.

```
HOST_OS=OSX
OSX_SETUP_HASH=3da3b4dc9f58
DEBIAN_SETUP_HASH=218a89a6aa7c
ARCH_SETUP_HASH=b086dbebc314
DEBIAN_REMOTE_SETUP_HASH=62e6dadd4ce6
ARCH_REMOTE_SETUP_HASH=4bd1cf33f9ea
DEBIAN_DOCKER_IMAGE=dotfiles-test-debian-218a89a6aa7c
ARCH_DOCKER_IMAGE=dotfiles-test-arch-b086dbebc314
DEBIAN_REMOTE_MINIMAL_IMAGE=dotfiles-test-debian-remote-62e6dadd4ce6
ARCH_REMOTE_MINIMAL_IMAGE=dotfiles-test-arch-remote-4bd1cf33f9ea
```

Full images (`*_DOCKER_IMAGE`) are picked up automatically by `run-tests.sh` for each test file. Minimal images (`*_MINIMAL_IMAGE`) use a distinct key suffix so the standard runner ignores them; `test-remote-configure.sh` reads them directly.

---

## Docker images

Docker images are built with the repo root as the build context, so the entire dotfiles repo is available during the build. The dotfiles setup script is run inside the image at build time, producing a ready-to-test environment.

**Full images** (built by `build-image.sh`):

| OS | Dockerfile | Base image |
|----|------------|------------|
| DEBIAN | `tests/docker/Dockerfile.ubuntu` | `ubuntu:24.04` |
| ARCH | `tests/docker/Dockerfile.arch` | `archlinux:latest` (forced `linux/amd64` — no arm64 image exists) |

Both full images:
- Create a non-root user `test` with passwordless `sudo`.
- Copy the repo into `/home/test/dotfiles`.
- Run `setup/setup.sh` as `test` during the build.

**Arch note:** pacman's seccomp sandbox (`alpm` user) fails under Rosetta emulation on Apple Silicon. `DisableSandbox` is set in `/etc/pacman.conf` before any `pacman` calls.

**Minimal (remote) images** (built by `build-image-remote.sh`):

| OS | Dockerfile | Base image |
|----|------------|------------|
| DEBIAN_REMOTE | `tests/docker/Dockerfile.ubuntu-remote` | `ubuntu:24.04` |
| ARCH_REMOTE | `tests/docker/Dockerfile.arch-remote` | `archlinux:latest` (forced `linux/amd64`) |

Both minimal images:
- Create a non-root user `test` with passwordless `sudo`.
- Install and start an SSH server (`openssh-server` / `openssh`).
- Accept a `HOST_PUBLIC_KEY` build arg and install it into `test`'s `authorized_keys` for passwordless SSH from the build host.
- Do **not** copy the repo or run any setup script — the dotfiles are deployed at test time by `deploy-remote-vm.sh`.

Image names encode the setup hash: `dotfiles-test-<os>-<hash>`. This makes images content-addressable — an unchanged setup always reuses the same image.

### Augmenting images with optional tools

Base images only contain what `setup/setup.sh` installs. To test an optional tool (Go, .NET, Docker) inside a container, augment the image with `augment-image.sh`:

```bash
# By OS shorthand + tool name
bash tests/docker/augment-image.sh debian go
bash tests/docker/augment-image.sh arch dotnet

# By full image name + explicit script path
bash tests/docker/augment-image.sh dotfiles-test-debian-5f0235439e97 go/configure_go.sh
```

This builds a new image `FROM` the existing one, re-copies the current dotfiles, runs the configure script, and retags the result with the **same image name**. `run-tests.sh` picks it up automatically — no changes to `.testenv` needed. `--no-cache` is always used to ensure the configure script actually runs.

---

## Test library

`tests/testlib.sh` is sourced by every test script and by the runner. It provides shared functions (log-level constants, log error/info/trace functions, ANSI colors, assertions, etc.).

---

## Test categories

Test files live in `tests/test-cases/` and are named `test-*.sh`. The runner auto-discovers them. Shared helpers live in `tests/test-cases/helpers/` and are not run directly.

### Core tests (always run)

Tests with **no** `REQUIRES` header. They verify the baseline setup produced by `setup/setup.sh` and must pass on every machine.

### Optional tests (run when tool is installed)

Tests that require a tool **not** installed by `setup.sh` declare a `REQUIRES` header at the top of the file:

```bash
# REQUIRES: code
```

The runner checks `command -v` for each listed command. In **default mode** the test is skipped when any required tool is absent. In **`--all` mode** it runs and fails if the tool is missing.

To add tests for a new optional tool, create `tests/test-cases/test-<tool>.sh` with the appropriate `REQUIRES` line. Multiple commands can be listed space-separated: `# REQUIRES: docker compose`.

---

## Troubleshooting

### Stale or inconsistent `.testenv`

`.testenv` can get out of sync with reality if a Docker image is deleted outside of the normal workflow (e.g. `docker rmi` run manually, disk cleanup, Docker Desktop reset).

**Symptoms:**
- `run-tests.sh` references an image that no longer exists
- `create-test-envs.sh` reports no changes but the image is missing

**Fix — force a full rebuild:**
```bash
rm tests/.testenv
bash tests/create-test-envs.sh
```

This discards all cached hashes and rebuilds every environment from scratch.

**Fix — rebuild a single OS only** (e.g. Debian):
Edit `tests/.testenv` and blank out (or delete) the relevant hash line:
```
DEBIAN_SETUP_HASH=
```
Then re-run `bash tests/create-test-envs.sh`. Only the OS with a changed or missing hash is rebuilt.

### Missing SSH public key (minimal/remote images)

If `create-test-envs.sh` prints `WARN: no SSH public key found — skipping remote image build`, the minimal Docker images won't be built and remote tests will be skipped.

**Fix:** ensure at least one of these files exists before running the script:
```
~/.ssh/id_ed25519.pub
~/.ssh/id_rsa.pub
~/.ssh/id_ecdsa.pub
```

---

## Scripts reference

| Script | Purpose |
|--------|---------|
| `tests/testlib.sh` | Shared test library (colors, log levels, `ok`/`fail`, counters). Sourced by all test scripts and the runner. |
| `tests/create-test-envs.sh` | Build/update test environments (local + Docker). Run this when setup files change. |
| `tests/run-tests.sh` | Run all test cases across all environments. |
| `tests/docker/build-image.sh` | Builds a single full Docker image. Accepts `IMAGE_NAME` and `DOCKERFILE_PATH` as env vars. |
| `tests/docker/build-image-remote.sh` | Builds a single minimal (SSH-enabled) Docker image. Same interface as `build-image.sh` plus `DOCKER_RUN_ARGS` for `--build-arg HOST_PUBLIC_KEY=<key>`. |
| `tests/docker/augment-image.sh` | Augments an existing test image by running a `configure_*.sh` script on top of it and retagging the result with the same name. Used to install optional tools (Go, .NET, Docker) into a test image so their optional tests can run. |

