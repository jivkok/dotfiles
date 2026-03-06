#!/usr/bin/env bash
set -euo pipefail

HELPERS="$(cd "$(dirname "$0")/helpers" && pwd)"

# ── Test helpers ──────────────────────────────────────────────────────────────
_pass=0
_fail=0

ok()   { echo "  OK  : $*"; _pass=$(( _pass + 1 )); }
fail() { echo "  FAIL: $*" >&2; _fail=$(( _fail + 1 )); }

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    ok "$label"
  else
    fail "$label (expected: '$expected', got: '$actual')"
  fi
}

assert_file_exists() { [[ -f "$1" ]] && ok "file exists: ${1##*/}" || fail "file missing: $1"; }
assert_file_absent()  { [[ ! -f "$1" ]] && ok "file absent: ${1##*/}"  || fail "file should not exist: $1"; }

assert_content() {
  grep -qF "$2" "$1" 2>/dev/null \
    && ok "content present: $2" \
    || fail "content missing '$2' in $1"
}

# ── Source testable functions (self-contained helper, works in all envs) ──────
# shellcheck source=helpers/vscode-functions.sh
source "${HELPERS}/vscode-functions.sh"

# ── Temp workspace ────────────────────────────────────────────────────────────
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

src="${tmpdir}/src"     # simulates the vscode/ source directory
dst="${tmpdir}/dst"     # simulates the editor User config directory
mkdir -p "${src}"

# Create valid JSON base config files
printf '{"editor.fontSize": 14}' > "${src}/settings.json"
printf '[{"key":"ctrl+c"}]'      > "${src}/keybindings.json"

# ── prepare_and_copy_vscode_config_files: skip conditions ─────────────────────
echo "--- prepare_and_copy_vscode_config_files: skip conditions ---"

# Skip when destination dir argument is empty string
prepare_and_copy_vscode_config_files "${src}" "settings" "linux" ""
ok "returns 0 (skip) when vscode_user_dir is empty"

# Skip when source base file is absent
mkdir -p "${dst}/skip-no-src"
prepare_and_copy_vscode_config_files "${src}" "nonexistent" "linux" "${dst}/skip-no-src"
ok "returns 0 (skip) when source file is absent"
assert_file_absent "${dst}/skip-no-src/nonexistent.json"

# ── prepare_and_copy_vscode_config_files: copy (no OS override) ───────────────
echo "--- prepare_and_copy_vscode_config_files: direct copy ---"

dest_copy="${dst}/copy"
prepare_and_copy_vscode_config_files "${src}" "settings" "linux" "${dest_copy}"
assert_file_exists "${dest_copy}/settings.json"
assert_content     "${dest_copy}/settings.json" '"editor.fontSize"'

# ── prepare_and_copy_vscode_config_files: merge with OS override ──────────────
echo "--- prepare_and_copy_vscode_config_files: merge with OS override ---"

printf '{"editor.fontFamily": "Fira Code"}' > "${src}/settings.linux.json"
dest_merge="${dst}/merge"
prepare_and_copy_vscode_config_files "${src}" "settings" "linux" "${dest_merge}"
assert_file_exists "${dest_merge}/settings.json"
assert_content     "${dest_merge}/settings.json" '"editor.fontSize"'
assert_content     "${dest_merge}/settings.json" '"editor.fontFamily"'

# ── prepare_and_copy_vscode_config_files: backup of existing file ─────────────
echo "--- prepare_and_copy_vscode_config_files: backup existing file ---"

dest_backup="${dst}/backup"
mkdir -p "${dest_backup}"
printf '{"old": true}' > "${dest_backup}/keybindings.json"
prepare_and_copy_vscode_config_files "${src}" "keybindings" "linux" "${dest_backup}"
assert_file_exists "${dest_backup}/keybindings.json"
backup_count=$(find "${dest_backup}" -name 'keybindings.json.*' | wc -l)
assert_eq "backup file created" "1" "${backup_count// /}"

# ── prepare_and_copy_vscode_config_files: creates dest dir if absent ──────────
echo "--- prepare_and_copy_vscode_config_files: creates dest dir ---"

dest_new="${dst}/new-dir-that-did-not-exist"
prepare_and_copy_vscode_config_files "${src}" "settings" "linux" "${dest_new}"
assert_file_exists "${dest_new}/settings.json"

# ── install_extensions: comment and blank line stripping ──────────────────────
echo "--- install_extensions: comment and blank line stripping ---"

ext_file="${tmpdir}/extensions.txt"
cat > "${ext_file}" <<'EOF'
# This is a comment
publisher.ext-one
publisher.ext-two  # inline comment

  # indented comment

EOF

_captured_exts=()

# Override install_extension to capture calls instead of running real installs
install_extension() {
  _captured_exts+=("$2")
  return 0
}

install_extensions "code" "${ext_file}" "${src}"
assert_eq "extension count"  "2"                   "${#_captured_exts[@]}"
assert_eq "first extension"  "publisher.ext-one"   "${_captured_exts[0]}"
assert_eq "second extension" "publisher.ext-two"   "${_captured_exts[1]}"

# ── Summary ───────────────────────────────────────────────────────────────────
echo
echo "Passed: ${_pass}, Failed: ${_fail}"
if [[ "${_fail}" -gt 0 ]]; then
  echo "==> FAILED."
  exit 1
fi
echo "==> PASSED."
