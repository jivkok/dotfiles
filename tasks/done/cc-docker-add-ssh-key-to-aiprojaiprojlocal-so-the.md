# Task: cc-docker: Add `ssh:` Key To .aiproj/.aiproj.local So The Containerized Claude Can Use Host SSH Aliases

**Status**: done
**Priority**: medium
**Created**: 2026-10-17

## Description

cc-docker: add `ssh:` key to .aiproj/.aiproj.local so the containerized Claude can use host SSH aliases (e.g. gitea-bot) to pull/push repos.

Decisions already made with the user:
- `ssh:` is an additive list of Host alias names from the host ~/.ssh/config, e.g. `ssh: [gitea-bot]`. Entries validated against ^[A-Za-z0-9][A-Za-z0-9._-]*$.
- Key delivery: copy (not ssh-agent). At each launch rebuild $STATE_DIR/host-ssh (dir 0700) from scratch, like the skills snapshot. Mount it read-only at /home/claude/.ssh.
- For each alias: resolve via `ssh -G <alias>` on the host (hostname, port, user, identityfile). Skip with a warning if unresolved or key file missing. Copy only the referenced key(s) to host-ssh/keys/<name> mode 0600. Write a minimal host-ssh/config per alias (HostName, Port, User, IdentityFile /home/claude/.ssh/keys/<name>, IdentitiesOnly yes, StrictHostKeyChecking yes); nothing else from the host config.
- known_hosts: copy only matching entries from host known_hosts via `ssh-keygen -F '[host]:port'` (StrictHostKeyChecking stays on). If no entry, warn with the fix (ssh-keyscan -p PORT HOST, or ssh once on the host).
- Log a security warning every run when ssh: is used (agent can read the key and use it wherever it has network access; keep the key scoped to needed repos).
- Image: add openssh-client and libnss-wrapper to ai/claude-code/Dockerfile for all projects (inert unless ssh: set), bump ai/claude-code/BUILD. The container runs as the host uid with no /etc/passwd entry, and ssh aborts with "No user exists for uid N"; so entrypoint.sh should, when ~/.ssh/config exists, write a passwd/group entry for the current uid and export NSS_WRAPPER_PASSWD, NSS_WRAPPER_GROUP, LD_PRELOAD=libnss_wrapper.so (resolve the lib path at runtime; differs between amd64 and arm64).
- FIRST verify nss_wrapper + ssh works under an arbitrary --user uid with a read-only ~/.ssh in a throwaway container. If it doesn't, fall back to a GIT_SSH_COMMAND wrapper script.
- Implementation near the skills block in ai/claude-code/claude-code-docker.sh (~line 830); parsing alongside the other CFG_* keys (~line 472+, including the yq-less fallback parser).
- Tests: extend tests/test-cases/test-docker-helpers.sh (alias resolution, invalid entry rejection, key mode 0600, minimal known_hosts, missing key skipped). Update the script header docs and docs/. Full suite (/run-tests --full) must pass.

Motivating example: host ~/.ssh/config has `Host gitea-bot / HostName git.uv2.kolevsfamily.com / User git / Port 2222 / IdentityFile ~/.ssh/id_ed25519_gitea / IdentitiesOnly yes`, and the repo remote is git@gitea-bot:jivko/intel.git; after this change git pull/push of that remote must work inside the container with `ssh: [gitea-bot]` in .aiproj.

## Acceptance Criteria

- [x] `claude-code-docker.sh` parses an `ssh:` list from `.aiproj[.yaml|.yml]` and `.aiproj.local` (via yq, and via the yq-less fallback parser); entries from both files are concatenated, primary first.
- [x] An `ssh:` entry not matching `^[A-Za-z0-9][A-Za-z0-9._-]*$` makes the script exit 1 with a `log_error` naming the entry, before any image build or `docker run`.
- [x] Before implementing, a throwaway container run as `--user 1234:1234` with a read-only `~/.ssh` shows whether `ssh -G <alias>` and `ssh -T` succeed with nss_wrapper (result recorded in Implementation Notes); if not, the `GIT_SSH_COMMAND` wrapper fallback is used instead.
- [x] When `ssh:` is set, `$STATE_DIR/host-ssh` is deleted and recreated on every launch with mode 0700 and mounted at `/home/claude/.ssh:ro`.
- [x] For each alias, `ssh -G <alias>` on the host supplies hostname, port, user and the identityfile; `host-ssh/config` contains one `Host <alias>` block per alias with exactly `HostName`, `Port`, `User`, `IdentityFile /home/claude/.ssh/keys/<name>`, `IdentitiesOnly yes`, `StrictHostKeyChecking yes`, and no other host config content.
- [x] Only the key file(s) referenced by the listed aliases are copied to `host-ssh/keys/<name>`, each with mode 0600; other keys in the host `~/.ssh` are not copied.
- [x] An alias whose identityfile is missing or unreadable is skipped with a `log_warning` naming the alias, and the launch continues; its Host block is not written.
- [x] `host-ssh/known_hosts` contains only the lines `ssh-keygen -F '[host]:port'` finds on the host for the listed aliases (plain `host` when port is 22).
- [x] When no known_hosts entry exists for an alias, a `log_warning` names the alias and suggests `ssh-keyscan -p <port> <host>` or connecting once on the host.
- [x] A `log_warning` stating that Claude can read the key and use it wherever the container has network access is emitted on every run where at least one alias is configured, and not when `ssh:` is absent.
- [x] When `ssh:` is absent or empty, no `host-ssh` mount is added and `docker_args` is identical to before.
- [x] `ai/claude-code/Dockerfile` installs `openssh-client` and `libnss-wrapper`, and `ai/claude-code/BUILD` is incremented.
- [x] `entrypoint.sh`, only when `$HOME/.ssh/config` exists, writes passwd and group entries for the current uid/gid to a writable temp location and exports `NSS_WRAPPER_PASSWD`, `NSS_WRAPPER_GROUP` and `LD_PRELOAD` pointing at the `libnss_wrapper.so` found at runtime (works on amd64 and arm64); otherwise it leaves the environment unchanged.
- [x] Inside the container started with `ssh: [gitea-bot]`, `git ls-remote` against `git@gitea-bot:jivko/intel.git` succeeds (manual verification, recorded in Implementation Notes).
- [x] `tests/test-cases/test-docker-helpers.sh` covers: alias resolution into the config, invalid entry rejection, key mode 0600, minimal known_hosts, missing key skipped.
- [x] The `ssh:` key is documented in the `claude-code-docker.sh` header comment and in the relevant `docs/` file(s).
- [x] `/run-tests --full` passes.

## Out of Scope

- ssh-agent forwarding.
- Forwarding the host's whole `~/.ssh` or any config directive beyond the six listed.
- Credential helpers, HTTPS tokens, or GPG/SSH commit signing.
- Writing the gitea-bot entry to any `.aiproj`, or changing the Gitea server or keys.
- Non-Linux-Docker engines needing special socket handling.
- Pruning or garbage-collecting old state.

## Edge Cases / Test Scenarios

- Alias with multiple IdentityFiles in `ssh -G` output: only the first existing file is used.
- Two aliases sharing one key file: the key is copied once and both blocks reference it.
- Alias with `ProxyJump`/`ProxyCommand`: not supported; warn and skip that alias.
- Hashed host `known_hosts` (`HashKnownHosts yes`): `ssh-keygen -F` handles it; output is copied as-is (hashed).
- Alias that `ssh -G` resolves to itself with no `HostName` (unknown alias): skipped with a warning, since no identityfile exists.
- `IdentityFile` with `~` or `%d` tokens: use the expanded path from `ssh -G`.
- Key filenames with the same basename in different directories: names deduplicated so they do not collide.
- `ssh:` set in `.aiproj.local` only; and `ssh: []`.
- Re-running the launch twice: the snapshot is rebuilt, with no stale keys from de-listed aliases.
- Host has no `~/.ssh/known_hosts` file.

## Assumptions

- The first existing IdentityFile from `ssh -G` is used when several are listed.
- ProxyJump/ProxyCommand aliases are unsupported and skipped with a warning (not required by the motivating example).
- The nss_wrapper passwd/group files are written under `/tmp` in the container (writable for any uid).
- User in the container config is the `User` from `ssh -G` (e.g. `git`), independent of the container's local username.
- Docs updates go in the script header and the docs file that already describes `.aiproj` keys (found by grep for `skills:`).
- A fresh `ssh-keygen -F` is run per alias against `~/.ssh/known_hosts` of the host user only.

## Implementation Notes

- Verified first: with `libnss-wrapper` preloaded and a passwd entry for the uid, ssh under `--user` with a read-only `~/.ssh` resolves the config and key; without it, `No user exists for uid`. So no `GIT_SSH_COMMAND` fallback was needed. Real end-to-end check against the Gitea server: `git ls-remote git@gitea-bot:jivko/intel.git` succeeded inside the built image.
- `ssh -G` answers for any name (default keys, hostname = the name), so an undefined alias would silently pick up e.g. `~/.ssh/id_ed25519`. The launcher therefore requires either a `HostName` differing from the alias or a literal `Host` line naming it; `Include`d aliases without `HostName` are skipped with a warning.
- `ssh -F ~/.ssh/config` and `ssh-keygen -f ~/.ssh/known_hosts` use `$HOME` explicitly (not the passwd home), so it follows the launcher's HOME and is testable with a fake home.
- Only `~/.ssh/known_hosts` is consulted (not `UserKnownHostsFile`/global known_hosts); hashed entries are copied as-is.
- An alias list that yields nothing usable removes the snapshot and adds no mount or security warning.
- Docs: no file under `docs/` mentions `.aiproj`, so the documentation lives in the `claude-code-docker.sh` header only, next to the other keys.
- Tests declare `REQUIRES: git ssh ssh-keygen`; they use `find`/`cat` rather than `ls`/`cmp` (the Arch test image has no `cmp`).
- The nss passwd/group entries are named `claude` and written to `/tmp` by the entrypoint; this is skipped entirely unless `~/.ssh/config` exists, so `LD_PRELOAD` is untouched for non-ssh projects. The new image has to be rebuilt (BUILD 4 -> 5) before `ssh:` works; this happens automatically on the next launch.

### Post-review changes
- Snapshot dir is now per launch (`mktemp -d $STATE_DIR/host-ssh.XXXXXX`) and removed by the exit trap, so concurrent sessions don't wipe each other's mounted keys and no key copy outlives the container. (The criterion "rebuilt on every launch" is met by construction.)
- Aliases with no explicit IdentityFile are skipped (identity list equal to `ssh -F /dev/null -G <unknown>`), so a default key like `~/.ssh/id_ed25519` is never copied; passphrase-protected keys are skipped with a warning (`ssh-keygen -y -P ""` probe).
- nss_wrapper passwd/group are now `/etc/passwd`+entry (ours first) instead of a one-line replacement, so root/system users still resolve. It is applied when the uid's passwd home != `$HOME` - not merely when the uid is missing: this host's uid 1000 collides with the base image's `ubuntu` user, which resolves but to `/home/ubuntu`, and ssh reads its config from the passwd home. Caught by the real-image end-to-end run, not by the stubbed tests.
- Known limits, documented in the script header: no `Include`/`Match` resolution, only `~/.ssh/known_hosts`, no `CertificateFile`.
