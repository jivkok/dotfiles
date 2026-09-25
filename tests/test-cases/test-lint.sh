#!/usr/bin/env bash
# COVERS: **/*.sh bin/*
# COVERAGE: meta
# Static checks for shell scripts:
#   - zsh -n              zsh files (under zsh/ without a bash shebang, or *.zsh)
#   - bash -n + shellcheck every other *.sh, and bin/* files with a sh/bash shebang
# Non-shell files (*.py, *.ps1, ...) are skipped.
#
# CHANGED_FILES (newline-separated repo-relative paths, exported by
# run-tests.sh --changed) limits the check to those files; otherwise every
# tracked script is checked.
set -euo pipefail

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

if [[ -n "${CHANGED_FILES:-}" ]]; then
  mapfile -t candidates < <(printf '%s\n' "$CHANGED_FILES" | sed '/^$/d' | sort -u)
else
  # shellcheck source=../coverage-lib.sh
  source "${repo_root}/tests/coverage-lib.sh"
  mapfile -t candidates < <(cov_tracked_files "$repo_root")
fi

# classify <path>  — set KIND to "zsh", "bash", or "" (skip). No subshell per file.
classify() {
  local path="$1" first=""
  KIND=""
  [[ -f "$path" ]] || return 0
  IFS= read -r first < "$path" || true
  case "$path" in
    *.zsh) KIND=zsh ;;
    zsh/*.sh)
      if [[ "$first" == '#!'*bash* ]]; then KIND=bash; else KIND=zsh; fi ;;
    *.sh) KIND=bash ;;
    bin/*)
      if [[ "$first" =~ ^#!.*(/|[[:space:]])(ba)?sh([[:space:]]|$) ]]; then KIND=bash; fi ;;
  esac
}

bash_files=()
zsh_files=()
for path in "${candidates[@]}"; do
  classify "$path"
  case "$KIND" in
    bash) bash_files+=("$path") ;;
    zsh) zsh_files+=("$path") ;;
  esac
done
log_trace "Linting ${#bash_files[@]} bash and ${#zsh_files[@]} zsh files"

# ── Syntax ─────────────────────────────────────────────────────────────────────
log_trace "--- syntax ---"
for f in "${bash_files[@]}"; do
  if out="$(bash -n "$f" 2>&1)"; then ok "bash -n $f"; else fail "bash -n $f: $out"; fi
done
if [[ ${#zsh_files[@]} -gt 0 ]]; then
  if command -v zsh >/dev/null 2>&1; then
    for f in "${zsh_files[@]}"; do
      if out="$(zsh -n "$f" 2>&1)"; then ok "zsh -n $f"; else fail "zsh -n $f: $out"; fi
    done
  else
    fail "zsh not installed; cannot syntax-check ${#zsh_files[@]} zsh files"
  fi
fi

# ── ShellCheck ─────────────────────────────────────────────────────────────────
log_trace "--- shellcheck ---"
if [[ ${#bash_files[@]} -gt 0 ]]; then
  if ! command -v shellcheck >/dev/null 2>&1; then
    fail "shellcheck not installed"
  else
    # Parallel batches: one shellcheck over every file is single-core and slow.
    report="$(printf '%s\0' "${bash_files[@]}" \
      | xargs -0 -n 8 -P "$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)" \
        shellcheck -f gcc 2>&1 || true)"
    for f in "${bash_files[@]}"; do
      findings="$(awk -v p="${f}:" 'index($0, p) == 1' <<< "$report")"
      if [[ -z "$findings" ]]; then
        ok "shellcheck $f"
      else
        fail "shellcheck $f:"$'\n'"$findings"
      fi
    done
  fi
fi

finish_test
