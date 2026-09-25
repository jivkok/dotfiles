#!/usr/bin/env bash
# shellcheck disable=SC2016  # single-quoted snippets expand in the child shell
# COVERS: sh/*.sh
# Unit tests for the shell function libraries in sh/ (loaded into every
# interactive bash and zsh session via sh/setenv.sh).
#
# Each snippet runs in a fresh `bash -c` / `zsh -c` that sources sh/helpers.sh
# plus the library under test, so the libraries are exercised exactly as the
# shells load them. helpers.sh, path.sh and marks.sh contain shell-specific
# syntax or branches and are asserted under both bash and zsh; the rest under
# bash. Functions that need a TTY, fzf, an editor, the network, sudo or
# macOS-only tools are only checked for being defined.
set -euo pipefail

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# Isolated HOME so nothing here can touch the real ~/.marks or other dotfiles.
mkdir -p "${tmpdir}/home"

shells=(bash)
if command -v zsh >/dev/null 2>&1; then shells+=(zsh); fi

# sh_run <shell> <lib> <snippet>  — run snippet after sourcing helpers.sh + lib.
# Prints the snippet's combined output; returns its exit code.
sh_run() {
  local shell="$1" lib="$2" snippet="$3"
  (cd "$tmpdir" && env -u SSH_TTY HOME="${tmpdir}/home" DOTDIR="$DOTDIR" MARKPATH="${tmpdir}/marks" "$shell" -c "
    dotdir=\"\$DOTDIR\"
    source \"\$dotdir/sh/helpers.sh\"
    source \"\$dotdir/sh/$lib\"
    $snippet" 2>&1)
}

# assert_rc <label> <expected> <snippet-args...>  — assert sh_run's exit code.
assert_rc() {
  local label="$1" expected="$2" rc=0
  shift 2
  sh_run "$@" >/dev/null || rc=$?
  assert_eq "$label (exit code)" "$expected" "$rc"
}

# ── helpers.sh ─────────────────────────────────────────────────────────────────
for sh in "${shells[@]}"; do
  log_trace "--- helpers.sh ($sh) ---"
  assert_rc "$sh: _has sh" 0 "$sh" helpers.sh '_has sh'
  assert_rc "$sh: _has missing command" 1 "$sh" helpers.sh '_has no-such-command-xyz'

  # _skip_gui is computed at source time from DOT_SKIP_GUI / SSH session vars.
  for case in "false:" "true:SSH_CONNECTION=10.0.0.1" "true:SSH_TTY=/dev/pts/9" \
    "false:DOT_SKIP_GUI=0 SSH_TTY=/dev/pts/9" "true:DOT_SKIP_GUI=1"; do
    expected="${case%%:*}" vars="${case#*:}"
    read -r -a env_args <<< "$vars"
    out="$(env -u SSH_TTY -u SSH_CONNECTION -u DOT_SKIP_GUI "${env_args[@]}" \
      "$sh" -c 'source "$1/sh/helpers.sh"; echo "$_skip_gui"' _ "$DOTDIR")"
    assert_eq "$sh: _skip_gui with [${vars:-no SSH, no DOT_SKIP_GUI}]" "$expected" "$out"
  done
done

# ── path.sh ────────────────────────────────────────────────────────────────────
mkdir -p "${tmpdir}/pdir"
for sh in "${shells[@]}"; do
  log_trace "--- path.sh ($sh) ---"
  for var in PATH MANPATH; do
    fn="_prepend_to_path"; [[ "$var" == MANPATH ]] && fn="_prepend_to_manpath"
    out="$(sh_run "$sh" path.sh "export MANPATH=\"\${MANPATH:-/usr/share/man}\"; $fn '${tmpdir}/pdir'; printf '%s' \"\$$var\"")"
    assert_eq "$sh: $fn prepends an existing dir" "${tmpdir}/pdir" "${out%%:*}"

    out="$(sh_run "$sh" path.sh "export MANPATH=\"\${MANPATH:-/usr/share/man}\"; $fn '${tmpdir}/pdir'; $fn '${tmpdir}/pdir'; printf '%s' \"\$$var\"")"
    count="$(tr ':' '\n' <<< "$out" | grep -cxF "${tmpdir}/pdir" || true)"
    assert_eq "$sh: $fn twice leaves one entry" "1" "$count"

    out="$(sh_run "$sh" path.sh "export MANPATH=\"\${MANPATH:-/usr/share/man}\"; before=\"\$$var\"; $fn '${tmpdir}/no-such-dir'; [ \"\$before\" = \"\$$var\" ] && echo unchanged")"
    assert_eq "$sh: $fn ignores a missing dir" "unchanged" "$out"
  done
done

# ── marks.sh ───────────────────────────────────────────────────────────────────
mkdir -p "${tmpdir}/target"
target_real="$(cd "${tmpdir}/target" && pwd -P)"
for sh in "${shells[@]}"; do
  log_trace "--- marks.sh ($sh) ---"
  rm -rf "${tmpdir}/marks"

  assert_rc "$sh: mark without a name" 1 "$sh" marks.sh 'mark'
  assert_rc "$sh: mark foo" 0 "$sh" marks.sh "cd '${tmpdir}/target' && mark foo"
  if [[ -L "${tmpdir}/marks/foo" && "$(readlink "${tmpdir}/marks/foo")" == "${tmpdir}/target" ]]; then
    ok "$sh: mark foo creates a symlink to \$PWD"
  else
    fail "$sh: mark foo did not create ${tmpdir}/marks/foo -> ${tmpdir}/target"
  fi

  run_capture sh_run "$sh" marks.sh "cd '${tmpdir}/target' && mark foo"
  assert_eq "$sh: duplicate mark (exit code)" "1" "$rc"
  assert_contains "$sh: duplicate mark message" "already exists" "$out"

  out="$(sh_run "$sh" marks.sh 'to foo && pwd -P')"
  assert_eq "$sh: to foo changes directory" "$target_real" "$out"

  out="$(sh_run "$sh" marks.sh 'to nope')"
  assert_eq "$sh: to unknown mark" "No such mark: nope" "$out"

  out="$(sh_run "$sh" marks.sh 'marks')"
  assert_contains "$sh: marks lists the name" "foo" "$out"
  assert_contains "$sh: marks shows the arrow" "->" "$out"
  assert_contains "$sh: marks shows the target" "${tmpdir}/target" "$out"

  sh_run "$sh" marks.sh 'echo y | unmark foo' >/dev/null || true
  if [[ ! -e "${tmpdir}/marks/foo" && ! -L "${tmpdir}/marks/foo" ]]; then
    ok "$sh: unmark removes the symlink"
  else
    fail "$sh: unmark left ${tmpdir}/marks/foo"
  fi
done

# ── utils.sh ───────────────────────────────────────────────────────────────────
log_trace "--- utils.sh: ex / lsz / targz ---"
mkdir -p "${tmpdir}/arch/src"
echo "hello" > "${tmpdir}/arch/src/file.txt"
(cd "${tmpdir}/arch" && tar czf src.tar.gz src && tar cf src.tar src)
echo "data" > "${tmpdir}/x.unknown"

mkdir -p "${tmpdir}/ex-gz" "${tmpdir}/ex-tar"
sh_run bash utils.sh "cd '${tmpdir}/ex-gz' && ex '${tmpdir}/arch/src.tar.gz'" >/dev/null
assert_file_exists "${tmpdir}/ex-gz/src/file.txt"
sh_run bash utils.sh "cd '${tmpdir}/ex-tar' && ex '${tmpdir}/arch/src.tar'" >/dev/null
assert_file_exists "${tmpdir}/ex-tar/src/file.txt"
assert_contains "ex: missing file" "is not a valid file" "$(sh_run bash utils.sh "ex '${tmpdir}/nope.tar.gz'")"
assert_contains "ex: unknown extension" "cannot be extracted" "$(sh_run bash utils.sh "ex '${tmpdir}/x.unknown'")"

assert_rc "lsz without arguments" 1 bash utils.sh 'lsz'
assert_contains "lsz lists archive members" "src/file.txt" "$(sh_run bash utils.sh "lsz '${tmpdir}/arch/src.tar.gz'")"

mkdir -p "${tmpdir}/tgz/pack"
echo "x" > "${tmpdir}/tgz/pack/a.txt"
sh_run bash utils.sh "cd '${tmpdir}/tgz' && targz pack" >/dev/null
assert_file_exists "${tmpdir}/tgz/pack.tar.gz"
assert_contains "targz archive contains the dir's files" "pack/a.txt" "$(tar tzf "${tmpdir}/tgz/pack.tar.gz")"

log_trace "--- utils.sh: encode / decode ---"
sample='a b&c/é'
encodings=(url base64)
if command -v python3 >/dev/null 2>&1; then encodings+=(html); fi
for enc in "${encodings[@]}"; do
  out="$(sh_run bash utils.sh "decode $enc \"\$(encode $enc '$sample')\"")"
  assert_eq "encode/decode $enc round-trip" "$sample" "$out"
done
assert_eq "encode url 'a b'" "a%20b" "$(sh_run bash utils.sh "encode url 'a b'")"
assert_contains "encode: unsupported encoding" "Unsupported encoding" "$(sh_run bash utils.sh "encode rot13 abc")"

log_trace "--- utils.sh: json / jdiff / dataurl / codepoint ---"
assert_contains "json formats piped JSON" '"a": 1' "$(sh_run bash utils.sh "echo '{\"a\":1}' | json")"

echo "same" > "${tmpdir}/j1"; echo "same" > "${tmpdir}/j2"; echo "other" > "${tmpdir}/j3"
mkdir -p "${tmpdir}/jdir"
# Hide difftastic and diff prettifiers: difft exits 0 even when files differ.
jdiff_env='_has() { case "$1" in difft|delta|diff-so-fancy|ydiff) return 1 ;; esac; command -v "$1" >/dev/null 2>&1; }; '
assert_rc "jdiff with wrong argument count" 1 bash utils.sh "${jdiff_env} jdiff '${tmpdir}/j1'"
assert_rc "jdiff with a missing path" 1 bash utils.sh "${jdiff_env} jdiff '${tmpdir}/j1' '${tmpdir}/nope'"
assert_rc "jdiff dir vs file" 1 bash utils.sh "${jdiff_env} jdiff '${tmpdir}/jdir' '${tmpdir}/j1'"
assert_rc "jdiff identical files" 0 bash utils.sh "${jdiff_env} jdiff '${tmpdir}/j1' '${tmpdir}/j2'"
check_not "jdiff differing files exits non-zero" sh_run bash utils.sh "${jdiff_env} jdiff '${tmpdir}/j1' '${tmpdir}/j3'"

echo "plain text" > "${tmpdir}/t.txt"
out="$(sh_run bash utils.sh "dataurl '${tmpdir}/t.txt'")"
assert_contains "dataurl text prefix" "data:text/plain;charset=utf-8;base64," "${out:0:40}"
assert_eq "codepoint A" "U+0041" "$(sh_run bash utils.sh 'codepoint A')"

# ── system.sh ──────────────────────────────────────────────────────────────────
log_trace "--- system.sh ---"
out="$(sh_run bash system.sh "cd '${tmpdir}' && (mkd a/b && pwd)")"
assert_eq "mkd creates and enters the dir" "${tmpdir}/a/b" "$out"
assert_dir "${tmpdir}/a/b"
out="$(sh_run bash system.sh 'PATH="/usr/bin:/bin:/usr/local/bin"; paths')"
assert_eq "paths prints one PATH entry per line" $'/usr/bin\n/bin\n/usr/local/bin' "$out"

# ── web.sh ─────────────────────────────────────────────────────────────────────
if command -v python3 >/dev/null 2>&1; then
  log_trace "--- web.sh ---"
  assert_eq "urlencode 'a b&c'" "a+b%26c" "$(sh_run bash web.sh "urlencode 'a b&c'")"
fi

# ── Sourcing only: edits / finds / sysinfo / ls ────────────────────────────────
declare -A lib_functions=(
  [edits.sh]="em ems emq"
  [finds.sh]="f d ff fs fsf fp fpf bat_theme_picker"
  [sysinfo.sh]="help diskusage sys_log history_top_commands"
  [ls.sh]=""
)
for sh in "${shells[@]}"; do
  for lib in edits.sh finds.sh sysinfo.sh ls.sh; do
    log_trace "--- $lib ($sh) ---"
    assert_rc "$sh: $lib sources under set -u" 0 "$sh" helpers.sh "set -u; source \"\$dotdir/sh/$lib\""
    for fn in ${lib_functions[$lib]}; do
      assert_rc "$sh: $lib defines $fn" 0 "$sh" "$lib" "type $fn"
    done
  done
done

# ── setenv.sh (aggregate loader) ───────────────────────────────────────────────
for sh in "${shells[@]}"; do
  log_trace "--- setenv.sh ($sh) ---"
  out=""; rc=0
  out="$(cd "$tmpdir" && env -u SSH_TTY HOME="${tmpdir}/home" DOTDIR="$DOTDIR" "$sh" -c 'dotdir="$DOTDIR"; source "$dotdir/sh/setenv.sh"' 2>&1)" || rc=$?
  assert_eq "$sh: sh/setenv.sh sources with exit code 0" "0" "$rc"
  assert_eq "$sh: sh/setenv.sh sources without output" "" "$out"
done

finish_test
