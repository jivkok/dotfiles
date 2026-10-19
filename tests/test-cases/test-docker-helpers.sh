#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2088  # single-quoted snippets expand in the child shell; literal ~ is passed to the script under test
# REQUIRES: git ssh ssh-keygen
# COVERS: docker/docker.sh ai/claude-code/claude-code-docker.sh
# Tests for the docker shell helpers (docker/docker.sh) and the Claude Code
# container launcher (ai/claude-code/claude-code-docker.sh). `docker` and
# `curl` are stubbed on PATH, so no daemon or network is needed; `jq` is real.
set -euo pipefail

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LAUNCHER="${DOTDIR}/ai/claude-code/claude-code-docker.sh"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

stubs="${tmpdir}/stubs"
mkdir -p "$stubs"
curl_log="${tmpdir}/curl.log"
run_log="${tmpdir}/docker-run.log"
build_log="${tmpdir}/docker-build.log"
dockerfile_log="${tmpdir}/project-dockerfile"

# curl stub: logs the URL (last argument), prints $STUB_CURL_OUT.
write_stub "${stubs}/curl" "$(cat <<EOF
echo "\${!#}" >> "$curl_log"
printf '%s\n' "\${STUB_CURL_OUT:-}"
EOF
)"
env_file_log="${tmpdir}/env-file"
ssh_snap="${tmpdir}/ssh-snap"      # copy of the mounted ssh dir, taken while `docker run` is "running"
ssh_mount_log="${tmpdir}/ssh-mount" # the mount's host-side source path
# docker stub: `images` prints $STUB_DOCKER_IMAGES; `run`/`build` log one arg per
# line; `run` also copies its --env-file (the launcher deletes it on exit).
write_stub "${stubs}/docker" "$(cat <<EOF
case "\$1" in
  images) [[ -n "\${STUB_DOCKER_IMAGES:-}" ]] && printf '%s\n' "\$STUB_DOCKER_IMAGES" ;;
  run)    shift; printf '%s\n' "\$@" > "$run_log"
          : > "$env_file_log"
          rm -rf "$ssh_snap" "$ssh_mount_log"
          for a in "\$@"; do case "\$a" in *:/home/claude/.ssh:ro) src="\${a%%:*}"; echo "\$src" > "$ssh_mount_log"; cp -R "\$src" "$ssh_snap" ;; esac; done
          while [ \$# -gt 1 ]; do [ "\$1" = --env-file ] && cat "\$2" > "$env_file_log"; shift; done ;;
  build)  shift; printf '%s\n' "\$@" > "$build_log"; [[ "\${!#}" == "-" ]] && cat > "$dockerfile_log" ;;
esac
exit 0
EOF
)"

# PATH without yq: the launcher's fallback .aiproj parser is under test.
STUB_PATH="${stubs}:$(path_without yq "$tmpdir")"

# PATH with yq: the real one when installed; otherwise a stand-in for
# `yq -r <filter> <file>` on the flat .aiproj format, converted to JSON and
# evaluated by the real jq (same filter semantics).
yq_stubs="${tmpdir}/yq-stubs"
mkdir -p "$yq_stubs"
write_stub "${yq_stubs}/yq" "$(cat <<'EOF'
python3 - "$3" <<'PY' | jq -r "$2"
import json, sys
def scalar(v):
    v = v.split(" #")[0].strip().strip('"').strip("'")
    return {"true": True, "false": False}.get(v, v)
doc, key = {}, None
for line in open(sys.argv[1]):
    if line.strip().startswith("- ") and key:
        doc.setdefault(key, []).append(scalar(line.strip()[2:]))
    elif ":" in line and not line[0].isspace():
        key, val = line.split(":", 1)
        if val.strip():
            doc[key] = scalar(val)
print(json.dumps(doc))
PY
EOF
)"
if command -v yq >/dev/null 2>&1; then
  YQ_PATH="${stubs}:${PATH}"
else
  YQ_PATH="${yq_stubs}:${STUB_PATH}"
fi

# ── docker/docker.sh: docker_tags ──────────────────────────────────────────────
log_trace "--- docker_tags ---"
tags_json='{"results":[{"name":"22.04","last_updated":"2024-01-01"},{"name":"24.04","last_updated":"2025-01-01"}]}'

# docker_sh <snippet>  — run snippet after sourcing docker.sh with stubs on PATH.
docker_sh() {
  PATH="$STUB_PATH" STUB_CURL_OUT="$tags_json" dotdir="$DOTDIR" \
    bash -c "source \"\$dotdir/docker/docker.sh\"; $1" 2>&1
}

run_capture docker_sh 'docker_tags'
assert_eq "docker_tags without args: exit code" "1" "$rc"
assert_contains "docker_tags without args: Usage" "Usage:" "$out"

: > "$curl_log"
docker_sh 'docker_tags ubuntu "" 1' >/dev/null
assert_file_content "$curl_log" "repositories/library/ubuntu/tags"
: > "$curl_log"
docker_sh 'docker_tags me/img "" 1' >/dev/null
assert_file_content "$curl_log" "repositories/me/img/tags"

: > "$curl_log"
out="$(docker_sh 'docker_tags ubuntu 22 1')"
assert_eq "docker_tags max pages 1: one request" "1" "$(wc -l < "$curl_log" | tr -d ' ')"
assert_eq "docker_tags filter keeps matching lines only" "22.04" "$out"

# ── docker/docker.sh: aliases/functions depend on docker being installed ──────
log_trace "--- docker.sh with/without docker ---"
out="$(docker_sh 'alias dps >/dev/null && type dexbash >/dev/null && echo defined')"
assert_eq "docker present: dps alias and dexbash defined" "defined" "$out"
no_docker_bin="${tmpdir}/no-docker-bin"
mkdir -p "$no_docker_bin"
out="$(PATH="$no_docker_bin" dotdir="$DOTDIR" "$BASH" -c \
  'source "$dotdir/docker/docker.sh"; alias dps >/dev/null 2>&1 || type dexbash >/dev/null 2>&1 || echo absent')"
assert_eq "docker absent: neither dps nor dexbash defined" "absent" "$out"

# ── claude-code-docker.sh ──────────────────────────────────────────────────────
build_n="$(cat "${DOTDIR}/ai/claude-code/BUILD")"
work="${tmpdir}/work"
fake_home="${tmpdir}/home"
state="${tmpdir}/state"
launcher_tmp="${tmpdir}/launcher-tmp"
mkdir -p "$work" "$fake_home" "$state" "$launcher_tmp"
stamp="${launcher_tmp}/ai-claude-code-version-check-$(id -u)"

# launch [args...]  — run the launcher from $work with stubs; env tweaks via caller.
launch() {
  (cd "${LAUNCH_DIR:-$work}" && env -u TMUX -u ANTHROPIC_API_KEY \
    PATH="${LAUNCH_PATH:-$STUB_PATH}" HOME="$fake_home" XDG_STATE_HOME="$state" TMPDIR="$launcher_tmp" \
    STUB_DOCKER_IMAGES="${STUB_DOCKER_IMAGES-ai-claude-code:1.2.3.${build_n}}" \
    STUB_CURL_OUT="${STUB_CURL_OUT:-}" \
    ${API_KEY:+ANTHROPIC_API_KEY="$API_KEY"} \
    bash "$LAUNCHER" "$@" 2>&1)
}
run_args() { cat "$run_log" 2>/dev/null; }
# has_arg_pair <a> <b>  — true if run args contain <a> immediately followed by <b>.
has_arg_pair() { run_args | grep -xF -A1 -- "$1" | grep -qxF -- "$2"; }

log_trace "--- claude-code-docker.sh: bash 3.2-safe array expansions ---"
# macOS's /bin/bash 3.2 (any bash < 4.4) fails `"${a[@]}"` on an empty array
# under set -u, so every possibly-empty array must be expanded as
# ${a[@]+"${a[@]}"}. Static check: no such bash in the test environments.
unguarded="$(sed -E 's/\$\{[A-Za-z_][A-Za-z0-9_]*\[@\]\+"\$\{[A-Za-z_][A-Za-z0-9_]*\[@\]\}"\}//g' "$LAUNCHER" \
  | grep -oE '"\$\{[A-Za-z_][A-Za-z0-9_]*\[@\]\}"' \
  | grep -vxE '"\$\{(docker_args|CONFIG_CANDIDATES)\[@\]\}"' || true)"
assert_eq "no unguarded expansion of a possibly-empty array" "" "$unguarded"

log_trace "--- claude-code-docker.sh: default run ---"
date +%Y-%m-%d > "$stamp"
rm -f "$run_log"
launch >/dev/null
check "mounts cwd at its own real host path" has_arg_pair -v "${work}:${work}"
check "sets -w to that same host path" has_arg_pair -w "${work}"
check "uses the tagged image" grep -qxF "ai-claude-code:1.2.3.${build_n}" "$run_log"
if run_args | tr '\n' ' ' | grep -qF "ai-claude-code:1.2.3.${build_n} claude --permission-mode auto"; then
  ok "runs claude --permission-mode auto"
else
  fail "claude --permission-mode auto missing in: $(run_args | tr '\n' ' ')"
fi
check "state kept under XDG_STATE_HOME" test -n "$(ls -A "$state")"

log_trace "--- claude-code-docker.sh: ccmux integration ---"
# TMUX_PANE is only passed along with the tmux socket bridge: it needs a real
# socket for the launcher's `-S` check, so bind one.
tmux_sock="${tmpdir}/tmux.sock"
python3 -c 'import socket,sys; s=socket.socket(socket.AF_UNIX); s.bind(sys.argv[1]); import time; time.sleep(30)' "$tmux_sock" &
sock_pid=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do [ -S "$tmux_sock" ] && break; sleep 0.2; done
rm -f "$run_log"
(cd "$work" && env -u ANTHROPIC_API_KEY TMUX="${tmux_sock},1,0" TMUX_PANE="%7" \
  PATH="$STUB_PATH" HOME="$fake_home" XDG_STATE_HOME="$state" TMPDIR="$launcher_tmp" \
  STUB_DOCKER_IMAGES="ai-claude-code:1.2.3.${build_n}" bash "$LAUNCHER" >/dev/null 2>&1)
kill "$sock_pid" 2>/dev/null
check "tmux bridge also passes TMUX_PANE" has_arg_pair -e "TMUX_PANE=%7"

rm -f "$run_log"
launch >/dev/null
check_not "no TMUX_PANE without a tmux bridge" grep -qF "TMUX_PANE=" "$run_log"
check_not "no ccmux mount when ccmux is not set up" grep -qF "ccmux" "$run_log"

mkdir -p "${fake_home}/.config/ccmux/session-pids"
rm -f "$run_log"
launch >/dev/null
check "mounts ccmux marker dir where the container's hook looks" \
  has_arg_pair -v "${fake_home}/.config/ccmux/session-pids:/home/claude/.config/ccmux/session-pids"

rm -rf "${fake_home}/.config/ccmux"
mkdir -p "${tmpdir}/ccmux-home/session-pids"
rm -f "$run_log"
CCMUX_HOME="${tmpdir}/ccmux-home" launch >/dev/null
check "CCMUX_HOME overrides the host marker dir" \
  has_arg_pair -v "${tmpdir}/ccmux-home/session-pids:/home/claude/.config/ccmux/session-pids"

log_trace "--- claude-code-docker.sh: CLI mount ---"
rm -f "$run_log"
launch '~/x:/x' >/dev/null
check "CLI mount expands ~" has_arg_pair -v "${fake_home}/x:/x"
check "CLI mount adds --add-dir /x" has_arg_pair --add-dir /x

log_trace "--- claude-code-docker.sh: CLI usage / unknown options ---"
rm -f "$stamp" "$run_log"
: > "$curl_log"
run_capture launch --help
assert_eq "--help: exit code" "0" "$rc"
assert_contains "--help: prints usage" "Usage: claude-code-docker.sh" "$out"
assert_file_absent "$run_log"
check_not "--help: no version check (parsed before any network/docker work)" test -s "$curl_log"
run_capture launch -h
assert_eq "-h: exit code" "0" "$rc"
run_capture launch --bogus
assert_eq "unknown option: exit code" "1" "$rc"
assert_contains "unknown option: error" 'unknown option "--bogus"' "$out"
run_capture launch notamount
assert_eq "positional without ':': exit code" "1" "$rc"
assert_contains "positional without ':': error" "is not a host_path:container_path mount" "$out"
assert_file_absent "$run_log"
date +%Y-%m-%d > "$stamp"

log_trace "--- claude-code-docker.sh: .aiproj volumes (no yq) ---"
printf 'volumes:\n  - /a:/b\n' > "${work}/.aiproj"
rm -f "$run_log"
launch >/dev/null
check ".aiproj volume mounted" has_arg_pair -v /a:/b
check ".aiproj volume adds --add-dir /b" has_arg_pair --add-dir /b
rm -f "${work}/.aiproj"

log_trace "--- claude-code-docker.sh: ANTHROPIC_API_KEY ---"
rm -f "$run_log"
launch >/dev/null
check_not "API key not forwarded when unset" grep -q '^ANTHROPIC_API_KEY=' "$run_log"
rm -f "$run_log"
API_KEY=sk-test launch >/dev/null
check "API key forwarded when set" grep -qxF 'ANTHROPIC_API_KEY=sk-test' "$run_log"

log_trace "--- claude-code-docker.sh: env (no yq) ---"
printf 'env:\n  - FROM_HOST   # passthrough\n  - UNSET_ONE\n  - LIT=a b\n' > "${work}/.aiproj"
printf 'env:\n  - LOCAL_LIT="x"\n' > "${work}/.aiproj.local"
rm -f "$run_log"
out="$(FROM_HOST=topsecret launch -e CLI_LIT=c)"
check "passthrough uses bare -e NAME" has_arg_pair -e FROM_HOST
check_not "passthrough value never in argv" grep -q topsecret "$run_log"
check_not "unset passthrough not passed" grep -qx UNSET_ONE "$run_log"
assert_contains "unset passthrough warns" "UNSET_ONE is not set" "$out"
check "literals use --env-file, not argv" grep -qxF -- --env-file "$run_log"
check_not "literal value not in argv" grep -q 'a b' "$run_log"
env_file_arg="$(grep -xF -A1 -- --env-file "$run_log" | tail -n1)"
check "env-file removed after run" test ! -e "$env_file_arg"
rm -f "${work}/.aiproj" "${work}/.aiproj.local"

log_trace "--- claude-code-docker.sh: env precedence (last entry per NAME wins) ---"
printf 'env:\n  - CFG_PASS\n  - CFG_LIT=from-config\n  - TWICE=first\n  - TWICE=second\n' > "${work}/.aiproj"
rm -f "$run_log"
CFG_PASS=host CFG_LIT=host launch -e CFG_PASS=from-cli -e CFG_LIT >/dev/null
check "CLI literal overrides config passthrough: literal in env-file" grep -qxF CFG_PASS=from-cli "$env_file_log"
check_not "CLI literal overrides config passthrough: no -e CFG_PASS" has_arg_pair -e CFG_PASS
check "CLI passthrough overrides config literal: -e CFG_LIT" has_arg_pair -e CFG_LIT
check_not "CLI passthrough overrides config literal: not in env-file" grep -q '^CFG_LIT=' "$env_file_log"
assert_eq "repeated literal: only the last is kept" "TWICE=second" "$(grep '^TWICE=' "$env_file_log")"
# An unset passthrough doesn't override an earlier literal of the same NAME.
rm -f "$run_log"
(unset CFG_LIT; launch -e CFG_LIT >/dev/null)
check "unset CLI passthrough keeps the config literal" grep -qxF CFG_LIT=from-config "$env_file_log"
rm -f "$run_log"
run_capture launch -e $'NL=a\nINJECTED=1'
assert_eq "literal with a newline: exit code" "1" "$rc"
assert_contains "literal with a newline: error" "can't contain a newline" "$out"
assert_file_absent "$run_log"
rm -f "${work}/.aiproj"

log_trace "--- claude-code-docker.sh: install -> derived image ---"
printf 'install:\n  - postgresql-client\n  - uv\n' > "${work}/.aiproj"
rm -f "$run_log" "$build_log" "$dockerfile_log"
launch >/dev/null
check "derived image built" test -s "$dockerfile_log"
check "Dockerfile based on base tag" grep -qxF "FROM ai-claude-code:1.2.3.${build_n}" "$dockerfile_log"
check "Dockerfile apt-installs postgresql-client" grep -q 'install.*postgresql-client' "$dockerfile_log"
check "Dockerfile has uv recipe" grep -q 'astral.sh/uv' "$dockerfile_log"
check "run uses the project image" grep -q '^ai-claude-code-proj:' "$run_log"
check "uv cache mounted" grep -q '/home/claude/.cache/uv$' "$run_log"
check "Dockerfile sets pipefail before any RUN (curl | sh fails the build)" \
  test "$(grep -m1 -E '^(SHELL|RUN) ' "$dockerfile_log")" = 'SHELL ["/bin/bash", "-o", "pipefail", "-c"]'
# The tag hashes the full generated Dockerfile, so editing a recipe's text
# (not only the package/recipe names) yields a new tag and a rebuild.
dockerfile_hash="$(sha256sum "$dockerfile_log" 2>/dev/null || shasum -a 256 "$dockerfile_log")"
check "project tag is the hash of the generated Dockerfile" \
  grep -qxF "ai-claude-code-proj:${dockerfile_hash:0:12}" "$run_log"
printf 'install:\n  - "bad pkg; rm -rf /"\n' > "${work}/.aiproj"
run_capture launch
assert_eq "invalid install entry: exit code" "1" "$rc"
rm -f "${work}/.aiproj"

log_trace "--- claude-code-docker.sh: --resume ---"
rm -f "$run_log"
launch -r 75fecbb5-64d8-465a-b65c-151a76e7bea7 >/dev/null
check "resume forwarded to claude" has_arg_pair --resume 75fecbb5-64d8-465a-b65c-151a76e7bea7
rm -f "$run_log"
launch --resume=abc >/dev/null
check "--resume=value form forwarded" has_arg_pair --resume abc
run_capture launch --resume
assert_eq "--resume with no value: exit code" "1" "$rc"
assert_contains "--resume with no value: error names the bare/picker form" "bare/picker form" "$out"
run_capture launch --resume --env
assert_eq "--resume followed by another flag: exit code" "1" "$rc"
run_capture launch --resume -x
assert_eq "--resume value looking like a flag: exit code" "1" "$rc"
assert_contains "--resume value looking like a flag: error" "looks like a flag" "$out"

log_trace "--- claude-code-docker.sh: docker: true ---"
printf 'docker: true\n' > "${work}/.aiproj"
rm -f "$run_log" "$dockerfile_log"
run_capture launch
if [ -S /var/run/docker.sock ]; then
  check "docker: true installs the docker-cli recipe" grep -q 'docker-compose-plugin' "$dockerfile_log"
  check "docker: true mounts host socket" has_arg_pair -v /var/run/docker.sock:/var/run/docker.sock
else
  assert_contains "docker: true without a socket: error" "Docker socket" "$out"
fi
rm -f "${work}/.aiproj"

log_trace "--- claude-code-docker.sh: worktrees: true ---"
wt_main="${tmpdir}/wt-main"
git init -q -b master "$wt_main"
git -C "$wt_main" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
wt_task="${fake_home}/worktrees/wt-main/task1"
mkdir -p "$(dirname "$wt_task")"
git -C "$wt_main" worktree add -q -b task1 "$wt_task"
wt_dir="$(cd -P "${fake_home}/worktrees/wt-main" && pwd -P)"
wt_common="$(cd -P "${wt_main}/.git" && pwd -P)"
printf 'worktrees: true\n' > "${wt_main}/.aiproj"
cp "${wt_main}/.aiproj" "${wt_task}/.aiproj"

# Main repo: the repo's worktrees dir is mounted at the same path and is an add-dir.
rm -f "$run_log"
LAUNCH_DIR="$wt_main" launch >/dev/null
check "worktrees: main repo mounts its worktrees dir at the same path" has_arg_pair -v "${wt_dir}:${wt_dir}"
check "worktrees: main repo worktrees dir is an --add-dir" has_arg_pair --add-dir "$wt_dir"
check_not "worktrees: main repo does not mount a git common dir" grep -qxF "${wt_common}:${wt_common}" "$run_log"

# Linked worktree: only the git common dir, and not as an --add-dir.
rm -f "$run_log"
LAUNCH_DIR="$wt_task" launch >/dev/null
check "worktrees: linked worktree mounts the git common dir at the same path" has_arg_pair -v "${wt_common}:${wt_common}"
check_not "worktrees: git common dir is not an --add-dir" has_arg_pair --add-dir "$wt_common"
check_not "worktrees: linked worktree does not mount the main working tree" grep -qxF "${wt_main}:${wt_main}" "$run_log"
check_not "worktrees: linked worktree does not mount the worktrees dir" grep -qxF "${wt_dir}:${wt_dir}" "$run_log"

# Without the key, nothing extra is mounted.
rm -f "${wt_main}/.aiproj" "$run_log"
LAUNCH_DIR="$wt_main" launch >/dev/null
check_not "worktrees: off by default" grep -qxF "${wt_dir}:${wt_dir}" "$run_log"

# .aiproj.local can switch a key off again: `false` is a value, not "absent" -
# with yq and with the fallback parser alike.
printf 'worktrees: true\n' > "${wt_main}/.aiproj"
printf 'worktrees: false\n' > "${wt_main}/.aiproj.local"
for parser in yq fallback; do
  rm -f "$run_log"
  parser_path="$STUB_PATH"
  [ "$parser" = yq ] && parser_path="$YQ_PATH"
  LAUNCH_PATH="$parser_path" LAUNCH_DIR="$wt_main" launch >/dev/null
  check_not "worktrees: .aiproj.local 'false' overrides 'true' (${parser})" \
    grep -qxF "${wt_dir}:${wt_dir}" "$run_log"
done
rm -f "${wt_main}/.aiproj.local" "$run_log"
LAUNCH_PATH="$YQ_PATH" LAUNCH_DIR="$wt_main" launch >/dev/null
check "worktrees: 'true' read via yq" has_arg_pair -v "${wt_dir}:${wt_dir}"

# A subdirectory launch would leave the worktree's .git unmounted: refused.
mkdir -p "${wt_main}/sub"
cp "${wt_main}/.aiproj" "${wt_main}/sub/.aiproj"
rm -f "$run_log"
LAUNCH_DIR="${wt_main}/sub" run_capture launch
assert_eq "worktrees: subdirectory launch: exit code" "1" "$rc"
assert_contains "worktrees: subdirectory launch: error names the root" "launched from the worktree root" "$out"
assert_file_absent "$run_log"
rm -rf "${wt_main}/sub"

# No task worktrees yet: nothing created on the host, nothing mounted.
wt_fresh="${tmpdir}/wt-fresh"
git init -q -b master "$wt_fresh"
printf 'worktrees: true\n' > "${wt_fresh}/.aiproj"
rm -f "$run_log"
LAUNCH_DIR="$wt_fresh" launch >/dev/null
check_not "worktrees: missing worktrees dir is not created on the host" test -e "${fake_home}/worktrees/wt-fresh"
check_not "worktrees: missing worktrees dir is not mounted" grep -qF "/worktrees/wt-fresh" "$run_log"
check "worktrees: run still launches" grep -qxF claude "$run_log"
rm -f "${wt_main}/.aiproj"

# Outside a git repo: warns and ignores.
printf 'worktrees: true\n' > "${work}/.aiproj"
rm -f "$run_log"
run_capture launch
assert_eq "worktrees: outside a git repo: exit code" "0" "$rc"
assert_contains "worktrees: outside a git repo: warning" "not a git repository" "$out"
rm -f "${work}/.aiproj"

log_trace "--- claude-code-docker.sh: skills: host skills sync ---"
host_skills="${fake_home}/.claude/skills"
synced="${state}/ai-claude-code/host-skills"
mkdir -p "${host_skills}/alpha" "${host_skills}/beta" "${tmpdir}/ext-skill"
echo a > "${host_skills}/alpha/SKILL.md"
echo b > "${host_skills}/beta/SKILL.md"
echo ext > "${tmpdir}/ext-skill/SKILL.md"
ln -s "${tmpdir}/ext-skill" "${host_skills}/linked"

# Default (no config): everything is synced, symlinks resolved, mounted read-only.
rm -f "$run_log"
launch >/dev/null
check "skills default: mounted read-only" has_arg_pair -v "${synced}:/home/claude/.claude/skills:ro"
check "skills default: plain skill copied" test -f "${synced}/alpha/SKILL.md"
check "skills default: symlinked skill copied as real files" test ! -L "${synced}/linked" -a -f "${synced}/linked/SKILL.md"

# skills: false -> no mount.
printf 'skills: false\n' > "${work}/.aiproj"
rm -f "$run_log"
launch >/dev/null
check_not "skills: false: no skills mount" grep -qF ":/home/claude/.claude/skills" "$run_log"

# List -> only named skills; a missing one warns; stale copies are dropped.
printf 'skills:\n  - alpha\n  - nope\n' > "${work}/.aiproj"
rm -f "$run_log"
run_capture launch
assert_contains "skills list: missing skill warns" 'skill "nope" not found' "$out"
check "skills list: named skill synced" test -f "${synced}/alpha/SKILL.md"
check_not "skills list: unnamed skill absent" test -e "${synced}/beta"

# Invalid name is rejected.
printf 'skills:\n  - ../etc\n' > "${work}/.aiproj"
run_capture launch
assert_eq "skills: invalid entry: exit code" "1" "$rc"
assert_contains "skills: invalid entry: message" "invalid skills entry" "$out"

# .aiproj.local overrides the primary file.
printf 'skills: true\n' > "${work}/.aiproj"
printf 'skills: false\n' > "${work}/.aiproj.local"
rm -f "$run_log"
launch >/dev/null
check_not "skills: .aiproj.local false overrides true" grep -qF ":/home/claude/.claude/skills" "$run_log"
rm -f "${work}/.aiproj" "${work}/.aiproj.local"

log_trace "--- claude-code-docker.sh: ssh: host SSH aliases ---"
host_ssh="${fake_home}/.ssh"
mode_of() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"; }
ssh_dirs_left() { find "${state}/ai-claude-code" -maxdepth 1 -name "host-ssh*"; }
mkdir -p "$host_ssh"
ssh-keygen -q -t ed25519 -N "" -f "${host_ssh}/id_bot"
ssh-keygen -q -t ed25519 -N "" -f "${host_ssh}/id_other"
ssh-keygen -q -t ed25519 -N "" -f "${tmpdir}/hostkey"
cat > "${host_ssh}/config" <<EOF
Host bot
    HostName git.example.test
    User git
    Port 2222
    IdentityFile ~/.ssh/id_bot
    IdentitiesOnly yes
Host bot2
    HostName git.example.test
    User git
    Port 2222
    IdentityFile ${host_ssh}/id_bot
Host nokey
    HostName nokey.example.test
    IdentityFile ~/.ssh/does-not-exist
Host jumpy
    HostName jumpy.example.test
    ProxyJump bot
    IdentityFile ~/.ssh/id_bot
Host secret
    HostName secret.example.test
    IdentityFile ~/.ssh/id_other
EOF
{
  printf '[git.example.test]:2222 %s\n' "$(cut -d' ' -f1,2 "${tmpdir}/hostkey.pub")"
  printf 'secret.example.test %s\n' "$(cut -d' ' -f1,2 "${tmpdir}/hostkey.pub")"
} > "${host_ssh}/known_hosts"

# No ssh: no mount, nothing created.
rm -f "$run_log"
launch >/dev/null
check_not "ssh absent: no ssh mount" grep -qF ":/home/claude/.ssh" "$run_log"
check "ssh absent: no host-ssh dir in state" test -z "$(ssh_dirs_left)"

# Alias resolved into a minimal config + only its key + only its known_hosts line.
printf 'ssh:\n  - bot\n' > "${work}/.aiproj"
rm -f "$run_log"
run_capture launch
check "ssh: mounted read-only at ~/.ssh" test -s "$ssh_mount_log"
check "ssh: snapshot removed on exit" test ! -e "$(cat "$ssh_mount_log")"
check "ssh: no host-ssh dirs left in state" test -z "$(ssh_dirs_left)"
assert_contains "ssh: security warning logged" "Claude can read them" "$out"
for want in "Host bot" "HostName git.example.test" "Port 2222" "User git" \
  "IdentityFile /home/claude/.ssh/keys/id_bot" "IdentitiesOnly yes" "StrictHostKeyChecking yes"; do
  assert_file_content "${ssh_snap}/config" "$want"
done
check "ssh: key copied" test "$(cat "${host_ssh}/id_bot")" = "$(cat "${ssh_snap}/keys/id_bot")"
check "ssh: key mode 0600" test "$(mode_of "${ssh_snap}/keys/id_bot")" = 600
check "ssh: dir mode 0700" test "$(mode_of "$ssh_snap")" = 700
check_not "ssh: unlisted key not copied" test -e "${ssh_snap}/keys/id_other"
check "ssh: known_hosts has the alias's line" grep -qF "[git.example.test]:2222" "${ssh_snap}/known_hosts"
check_not "ssh: known_hosts lacks other hosts" grep -qF "secret.example.test" "${ssh_snap}/known_hosts"
check_not "ssh: no unrelated host config" grep -qF "secret" "${ssh_snap}/config"

# Two aliases sharing one key: copied once, both blocks reference it.
printf 'ssh:\n  - bot\n  - bot2\n' > "${work}/.aiproj"
launch >/dev/null
assert_eq "ssh: shared key copied once" "1" "$(find "${ssh_snap}/keys" -type f | wc -l | tr -d ' ')"
assert_eq "ssh: both blocks use the shared key" "2" "$(grep -cF 'IdentityFile /home/claude/.ssh/keys/id_bot' "${ssh_snap}/config")"

# Skipped aliases: missing key, ProxyJump, undefined Host.
printf 'ssh:\n  - nokey\n  - jumpy\n  - ghost\n' > "${work}/.aiproj"
rm -f "$run_log"
run_capture launch
assert_contains "ssh: missing key warns" "ssh: nokey: no readable IdentityFile" "$out"
assert_contains "ssh: ProxyJump warns" "ssh: jumpy: ProxyJump/ProxyCommand is not supported" "$out"
assert_contains "ssh: undefined alias warns" "ssh: ghost: no such Host" "$out"
assert_eq "ssh: launch continues after skips: exit code" "0" "$rc"
check_not "ssh: nothing usable: no ssh mount" grep -qF ":/home/claude/.ssh" "$run_log"
check_not "ssh: nothing usable: no security warning" grep -qF "Claude can read them" <<<"$out"

# Missing known_hosts entry warns with the fix.
printf 'ssh:\n  - secret\n' > "${work}/.aiproj"
: > "${host_ssh}/known_hosts"
run_capture launch
assert_contains "ssh: no known_hosts entry warns" "ssh-keyscan -p 22 secret.example.test" "$out"

# Concurrent sessions get distinct snapshot dirs; none are left behind.
printf 'ssh:\n  - bot\n' > "${work}/.aiproj"
launch >/dev/null; first_mount="$(cat "$ssh_mount_log")"
launch >/dev/null; second_mount="$(cat "$ssh_mount_log")"
check "ssh: each launch uses its own snapshot dir" test "$first_mount" != "$second_mount"
check "ssh: no snapshot dirs left after both exits" test -z "$(ssh_dirs_left)"

# Aliases without an explicit IdentityFile never copy a default key.
cat >> "${host_ssh}/config" <<EOF
Host nodefault
    HostName nodefault.example.test
EOF
cp "${host_ssh}/id_other" "${host_ssh}/id_ed25519"
printf 'ssh:\n  - nodefault\n' > "${work}/.aiproj"
run_capture launch
assert_contains "ssh: default key refused" "ssh: nodefault: no explicit IdentityFile" "$out"
check_not "ssh: default key not mounted" test -s "$ssh_mount_log"
rm -f "${host_ssh}/id_ed25519"

# A passphrase-protected key can't be used non-interactively: skipped.
ssh-keygen -q -t ed25519 -N "secretpass" -f "${host_ssh}/id_locked"
cat >> "${host_ssh}/config" <<EOF
Host locked
    HostName locked.example.test
    IdentityFile ~/.ssh/id_locked
EOF
printf 'ssh:\n  - locked\n' > "${work}/.aiproj"
run_capture launch
assert_contains "ssh: passphrase-protected key skipped" "ssh: locked: key" "$out"
assert_contains "ssh: passphrase warning text" "passphrase-protected" "$out"

# Invalid entry is rejected before anything runs.
printf 'ssh:\n  - "bad host"\n' > "${work}/.aiproj"
rm -f "$run_log"
run_capture launch
assert_eq "ssh: invalid entry: exit code" "1" "$rc"
assert_contains "ssh: invalid entry: message" "invalid ssh entry" "$out"
assert_file_absent "$run_log"

# .aiproj.local adds to the primary list.
printf 'ssh:\n  - bot\n' > "${work}/.aiproj"
printf 'ssh:\n  - secret\n' > "${work}/.aiproj.local"
launch >/dev/null
for want in "Host bot" "Host secret"; do assert_file_content "${ssh_snap}/config" "$want"; done
rm -f "${work}/.aiproj" "${work}/.aiproj.local"

log_trace "--- claude-code-docker.sh: unresolvable version, no image ---"
rm -f "$stamp" "$run_log"
STUB_DOCKER_IMAGES="" STUB_CURL_OUT="garbage" run_capture launch
assert_eq "no image + bad version: exit code" "1" "$rc"
assert_contains "no image + bad version: error message" "couldn't resolve" "$out"
assert_file_absent "$run_log"

log_trace "--- claude-code-docker.sh: newer version triggers a build ---"
rm -f "$stamp" "$build_log"
STUB_CURL_OUT="9.9.9" launch >/dev/null
check "docker build with CLAUDE_CODE_VERSION=9.9.9" grep -qxF "CLAUDE_CODE_VERSION=9.9.9" "$build_log"

finish_test
