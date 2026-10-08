#!/usr/bin/env bash
# COVERS: setup/deploy-remote-vm.sh
# Exit-status contract of setup/deploy-remote-vm.sh, with `rsync` and `ssh`
# stubbed on PATH (no network or containers; test-remote-configure.sh covers
# a real deploy): a failed rsync or remote setup must fail the deploy.
set -euo pipefail

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEPLOY="${DOTDIR}/setup/deploy-remote-vm.sh"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "${tmpdir}/stubs" "${tmpdir}/home"

# Each stub logs its argv and exits with $STUB_<NAME>_RC (default 0).
write_stub "${tmpdir}/stubs/rsync" "echo \"rsync \$*\" >> '${tmpdir}/calls'; exit \"\${STUB_RSYNC_RC:-0}\""
write_stub "${tmpdir}/stubs/ssh" "echo \"ssh \$*\" >> '${tmpdir}/calls'; exit \"\${STUB_SSH_RC:-0}\""

# deploy [env...]  — run the deploy against a fake host; sets out/rc.
deploy() {
  : > "${tmpdir}/calls"
  run_capture env HOME="${tmpdir}/home" PATH="${tmpdir}/stubs:${PATH}" "$@" \
    bash "$DEPLOY" -p 2222 test@example.invalid
}

log_trace "--- deploy-remote-vm.sh: success ---"
deploy
assert_eq "success: exit code" "0" "$rc"
check "success: rsyncs then runs setup-remote-vm.sh over ssh" \
  grep -q '^ssh .*-p 2222 .*setup-remote-vm.sh' "${tmpdir}/calls"

log_trace "--- deploy-remote-vm.sh: remote setup fails ---"
deploy STUB_SSH_RC=3
assert_eq "remote failure: exit code propagated" "3" "$rc"
assert_contains "remote failure: error names the exit code" "failed (exit 3)" "$out"

deploy STUB_SSH_RC=255
assert_eq "ssh connection failure: exit code propagated" "255" "$rc"

log_trace "--- deploy-remote-vm.sh: rsync fails ---"
deploy STUB_RSYNC_RC=12
assert_eq "rsync failure: exit code propagated" "12" "$rc"
check_not "rsync failure: remote setup not run" grep -q '^ssh ' "${tmpdir}/calls"

finish_test
