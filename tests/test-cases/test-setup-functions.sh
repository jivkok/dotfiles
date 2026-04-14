#!/usr/bin/env bash
# Unit tests for shared helpers in setup/setup_functions.sh.
# No specific tool required — runs locally and in all Docker environments.
set -uo pipefail

DOTDIR="$(cd "$(dirname "$0")/../.." && pwd)"

# Source testlib first for ok/fail/finish_test/assert_*.
# setup_functions.sh is sourced next and overrides log_* with LOG_LEVEL-aware
# versions, but ok/fail/finish_test/assert_* from testlib remain intact.
# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"
# shellcheck source=../../setup/setup_functions.sh
source "$DOTDIR/setup/setup_functions.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# ── LOG_LEVEL filtering ────────────────────────────────────────────────────────
log_trace "--- LOG_LEVEL filtering ---"

# log_trace is suppressed at default level (2)
output=$(LOG_LEVEL=2 bash -c "source '$DOTDIR/setup/setup_functions.sh'; log_trace 'hello'" 2>/dev/null)
if [ -z "$output" ]; then
  ok "log_trace suppressed at LOG_LEVEL=2"
else
  fail "log_trace should be suppressed at LOG_LEVEL=2 (got output)"
fi

# log_trace is emitted at level 3
output=$(LOG_LEVEL=3 bash -c "source '$DOTDIR/setup/setup_functions.sh'; log_trace 'hello'" 2>/dev/null)
if [ -n "$output" ]; then
  ok "log_trace emitted at LOG_LEVEL=3"
else
  fail "log_trace should be emitted at LOG_LEVEL=3"
fi

# log_info is emitted at default level (2)
output=$(LOG_LEVEL=2 bash -c "source '$DOTDIR/setup/setup_functions.sh'; log_info 'hello'" 2>/dev/null)
if [ -n "$output" ]; then
  ok "log_info emitted at LOG_LEVEL=2"
else
  fail "log_info should be emitted at LOG_LEVEL=2"
fi

# log_info is suppressed below level 2
output=$(LOG_LEVEL=1 bash -c "source '$DOTDIR/setup/setup_functions.sh'; log_info 'hello'" 2>/dev/null)
if [ -z "$output" ]; then
  ok "log_info suppressed at LOG_LEVEL=1"
else
  fail "log_info should be suppressed at LOG_LEVEL=1 (got output)"
fi

# log_warning is emitted at level 1
output=$(LOG_LEVEL=1 bash -c "source '$DOTDIR/setup/setup_functions.sh'; log_warning 'hello'" 2>/dev/null)
if [ -n "$output" ]; then
  ok "log_warning emitted at LOG_LEVEL=1"
else
  fail "log_warning should be emitted at LOG_LEVEL=1"
fi

# log_warning is suppressed below level 1
output=$(LOG_LEVEL=0 bash -c "source '$DOTDIR/setup/setup_functions.sh'; log_warning 'hello'" 2>/dev/null)
if [ -z "$output" ]; then
  ok "log_warning suppressed at LOG_LEVEL=0"
else
  fail "log_warning should be suppressed at LOG_LEVEL=0 (got output)"
fi

# log_error always emits regardless of LOG_LEVEL
output=$(LOG_LEVEL=0 bash -c "source '$DOTDIR/setup/setup_functions.sh'; log_error 'hello'" 2>/dev/null)
if [ -n "$output" ]; then
  ok "log_error emits at LOG_LEVEL=0"
else
  fail "log_error should always emit"
fi

# ── download_file ──────────────────────────────────────────────────────────────
log_trace "--- download_file ---"

# Successful download via file:// URL
echo "test-content" > "$tmpdir/dl-source.txt"
download_file "file://$tmpdir/dl-source.txt" "$tmpdir/dl-dest.txt"
assert_file_exists "$tmpdir/dl-dest.txt"
assert_file_content "$tmpdir/dl-dest.txt" "test-content"

# Failed download: non-zero exit, no leftover file at destination
bad_dest="$tmpdir/bad-download.txt"
if download_file "file:///nonexistent/path/does/not/exist" "$bad_dest" 2>/dev/null; then
  fail "download_file: should return non-zero on bad URL"
else
  ok "download_file: returns non-zero on bad URL"
fi
assert_file_absent "$bad_dest"

# ── backup_file_if_exists ─────────────────────────────────────────────────────
log_trace "--- backup_file_if_exists ---"

# No-op on absent file
backup_file_if_exists "$tmpdir/nonexistent.txt"
ok "backup_file_if_exists: no-op on absent file"

# Creates timestamped backup
echo "original" > "$tmpdir/backup-test.txt"
backup_file_if_exists "$tmpdir/backup-test.txt"
backup_count=$(find "$tmpdir" -maxdepth 1 -name "backup-test.txt.*" | wc -l | tr -d ' ')
assert_eq "backup_file_if_exists: backup created" "1" "$backup_count"

# Backup name matches YYYY-MM-DD_HH-MM-SS format
backup_name=$(find "$tmpdir" -maxdepth 1 -name "backup-test.txt.*" | head -1)
if echo "$backup_name" | grep -qE 'backup-test\.txt\.[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}'; then
  ok "backup_file_if_exists: backup name matches timestamp format"
else
  fail "backup_file_if_exists: unexpected backup name format: $backup_name"
fi

# Original file still present after backup
assert_file_exists "$tmpdir/backup-test.txt"

# Counter suffix on same-second collision:
# Pre-create a backup at the current timestamp; the function must produce a
# second backup (either at the same timestamp with .1 suffix, or at the next
# second) — either way two backups exist and no data is lost.
echo "dup-data" > "$tmpdir/dup.txt"
ts=$(date +"%Y-%m-%d_%H-%M-%S")
echo "pre-existing" > "$tmpdir/dup.txt.$ts"
backup_file_if_exists "$tmpdir/dup.txt"
dup_count=$(find "$tmpdir" -maxdepth 1 -name "dup.txt.*" | wc -l | tr -d ' ')
if [ "$dup_count" -ge 2 ]; then
  ok "backup_file_if_exists: collision produces second backup"
else
  fail "backup_file_if_exists: expected 2 backups after collision, got $dup_count"
fi

# ── backup_folder_if_exists ───────────────────────────────────────────────────
log_trace "--- backup_folder_if_exists ---"

# No-op on absent directory
backup_folder_if_exists "$tmpdir/absent-dir"
ok "backup_folder_if_exists: no-op on absent directory"

# Creates timestamped backup of directory
mkdir -p "$tmpdir/mydir"
echo "content" > "$tmpdir/mydir/file.txt"
backup_folder_if_exists "$tmpdir/mydir"
dir_backup_count=$(find "$tmpdir" -maxdepth 1 -name "mydir.*" -type d | wc -l | tr -d ' ')
assert_eq "backup_folder_if_exists: backup created" "1" "$dir_backup_count"

# Backup contains the original files
dir_backup=$(find "$tmpdir" -maxdepth 1 -name "mydir.*" -type d | head -1)
assert_file_exists "$dir_backup/file.txt"

# Original directory still present
assert_dir "$tmpdir/mydir"

# ── append_or_merge_file ──────────────────────────────────────────────────────
log_trace "--- append_or_merge_file ---"

# Target absent: source is copied verbatim
printf 'line1\nline2\n' > "$tmpdir/src.txt"
append_or_merge_file "$tmpdir/src.txt" "$tmpdir/merged-new.txt"
assert_file_exists "$tmpdir/merged-new.txt"
assert_file_content "$tmpdir/merged-new.txt" "line1"
assert_file_content "$tmpdir/merged-new.txt" "line2"

# Target already contains all lines: no duplicate lines added
printf 'line1\nline2\n' > "$tmpdir/uptodate.txt"
append_or_merge_file "$tmpdir/src.txt" "$tmpdir/uptodate.txt"
line_count=$(grep -c '' "$tmpdir/uptodate.txt")
assert_eq "append_or_merge_file: idempotent (no duplicates)" "2" "$line_count"

# Target missing some lines: only missing lines appended
printf 'line1\n' > "$tmpdir/partial.txt"
append_or_merge_file "$tmpdir/src.txt" "$tmpdir/partial.txt"
assert_file_content "$tmpdir/partial.txt" "line2"
line_count=$(grep -c '' "$tmpdir/partial.txt")
assert_eq "append_or_merge_file: missing line appended" "2" "$line_count"

# ── Summary ───────────────────────────────────────────────────────────────────
finish_test
