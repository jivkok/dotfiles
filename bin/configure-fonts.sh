#!/usr/bin/env bash
set -euo pipefail

# Summary:
# Pull fonts from a dedicated GitHub repo, update a local (inside dotfiles) folder, and install fonts if the current host is not a Linux VM.

# Requirements:
# - Download all fonts from the GitHub repo. Use a robust method (like downloading a repo archive/zip/tarball) rather than per-file URLs.
# - When updating the local dotfiles fonts folder, do not delete font files that exist locally but not upstream
# - Script must be idempotent and safe to re-run.
# - Keep local cache to minimize the unnecessary downloads from the remote repo.
# - Provide clear logging and fail fast on errors.
# - OS-specific details:
#   - macOS: install fonts for the current user. Target dir: ~/Library/Fonts
#   - Linux: install fonts only on bare metal (non-VM). Target dir: ~/.local/share/fonts. Provide an override env var: DOTFILES_FORCE_FONTS_INSTALL=1 to force fonts installation.

# Settings:
# - Fonts remote repo: https://github.com/jivkok/fonts, branch: main.
# - Local Cache Location (inside dotfiles): `/fonts`. Note: that folder is in .gitignore.

# ---- Configuration defaults (overridable via env) ----
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Script lives at $DOTFILES_ROOT/bin/; go up one level to reach dotfiles root.
DEFAULT_DOTFILES_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
DOTFILES_ROOT="${DOTFILES_ROOT:-$DEFAULT_DOTFILES_ROOT}"

DOTFILES_FONTS_DIR="${DOTFILES_FONTS_DIR:-$DOTFILES_ROOT/fonts}"

# Repo settings
FONTS_REPO_OWNER="${FONTS_REPO_OWNER:-jivkok}"
FONTS_REPO_NAME="${FONTS_REPO_NAME:-fonts}"
FONTS_REPO_REF="${FONTS_REPO_REF:-main}"

# Linux-only override: force install even if VM detected
DOTFILES_FORCE_FONTS_INSTALL="${DOTFILES_FORCE_FONTS_INSTALL:-0}"

# Caching
TMPDIR_BASE="${TMPDIR_BASE:-${TMPDIR:-/tmp}}"
DOTFILES_CACHE_DIR="${DOTFILES_CACHE_DIR:-$TMPDIR_BASE/fontscache}"
REPO_META_FILE="$DOTFILES_CACHE_DIR/fonts_repo_meta.json"
REPO_PUSHED_AT_FILE="$DOTFILES_CACHE_DIR/fonts_repo_pushed_at"
ARCHIVE_CACHE_FILE="$DOTFILES_CACHE_DIR/fonts_repo.tar.gz"

# Font extensions to sync/install
FONT_EXTS=(
  "ttf" "otf" "ttc" "otc" "woff" "woff2"
)

# Helper funtions

log()  { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
die()  { log "ERROR: $*"; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
is_linux() { [[ "$(uname -s)" == "Linux" ]]; }

# VM detection for Linux:
# - Prefer systemd-detect-virt (no sudo, reliable on systemd hosts)
# - Fallback to DMI strings without sudo
# - Last resort: dmidecode (may require sudo); if sudo unavailable / denied, treat as "unknown". Treat unknown as "VM"
is_vm_linux() {
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    systemd-detect-virt --quiet && return 0 || return 1
  fi

  # DMI without sudo
  local dmi_paths=(
    "/sys/class/dmi/id/sys_vendor"
    "/sys/class/dmi/id/product_name"
    "/sys/class/dmi/id/board_vendor"
    "/sys/class/dmi/id/bios_vendor"
  )
  local dmi=""
  for p in "${dmi_paths[@]}"; do
    if [[ -r "$p" ]]; then
      dmi+=$'\n'
      dmi+="$(cat "$p" 2>/dev/null || true)"
    fi
  done
  if [[ -n "$dmi" ]]; then
    echo "$dmi" | grep -qiE 'KVM|QEMU|VirtualBox|VMware|Microsoft Corporation|Hyper-V|Xen|Bochs' && return 0 || return 1
  fi

  # dmidecode (may need sudo)
  if command -v dmidecode >/dev/null 2>&1; then
    if command -v sudo >/dev/null 2>&1; then
      # Avoid prompting forever; if sudo needs a password and no tty, it will fail fast.
      if sudo -n true >/dev/null 2>&1; then
        sudo dmidecode -s system-manufacturer -s system-product-name 2>/dev/null \
          | grep -qiE 'KVM|QEMU|VirtualBox|VMware|Microsoft Corporation|Hyper-V|Xen|Bochs' && return 0 || return 1
      else
        # Try interactive sudo as a best-effort; if it fails, fall through.
        if sudo dmidecode -s system-manufacturer -s system-product-name 2>/dev/null \
          | grep -qiE 'KVM|QEMU|VirtualBox|VMware|Microsoft Corporation|Hyper-V|Xen|Bochs'
        then
          return 0
        else
          return 1
        fi
      fi
    else
      # dmidecode exists but no sudo; try anyway (might work as root)
      dmidecode -s system-manufacturer -s system-product-name 2>/dev/null \
        | grep -qiE 'KVM|QEMU|VirtualBox|VMware|Microsoft Corporation|Hyper-V|Xen|Bochs' && return 0 || return 1
    fi
  fi

  # Unknown: treat as VM
  return 0
}

# GitHub helpers (no auth)

github_api_get_repo_json() {
  local url="https://api.github.com/repos/${FONTS_REPO_OWNER}/${FONTS_REPO_NAME}"
  # GitHub prefers a User-Agent; some environments may require it.
  curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    -H "User-Agent: dotfiles-fonts-sync" \
    "$url"
}

# JSON "parser" (string values only) to avoid jq dependency
# usage: json_get_string "$json" "key"
json_get_string() {
  local json="$1" key="$2"
  printf '%s' "$json" \
    | tr -d '\n' \
    | sed -nE "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"([^\"]+)\".*/\1/p" \
    | head -n1
}

ensure_dirs() {
  mkdir -p "$DOTFILES_FONTS_DIR" "$DOTFILES_CACHE_DIR"
}

build_rsync_font_filters() {
  # Emit rsync include/exclude rules to stdout
  # Always include directories, include matching extensions (case-insensitive not supported directly),
  # so include both lower and upper variants.
  echo "--include=*/"
  for ext in "${FONT_EXTS[@]}"; do
    echo "--include=*.${ext}"
    echo "--include=*.${ext^^}"
  done
  echo "--exclude=*"
}

sync_fonts_cache() {
  ensure_dirs
  need_cmd curl
  need_cmd tar
  need_cmd rsync

  log "Reading repo metadata (unauthenticated GitHub API)..."
  local repo_json default_branch pushed_at
  repo_json="$(github_api_get_repo_json)" || die "Failed to query GitHub repo metadata"
  default_branch="$(json_get_string "$repo_json" "default_branch")"
  pushed_at="$(json_get_string "$repo_json" "pushed_at")"

  [[ -n "$default_branch" ]] || die "Could not determine default_branch from GitHub API response"
  [[ -n "$pushed_at" ]] || die "Could not determine pushed_at from GitHub API response"

  mkdir -p "$DOTFILES_CACHE_DIR"
  printf '%s\n' "$repo_json" >"$REPO_META_FILE"

  if [[ "$default_branch" != "$FONTS_REPO_REF" ]]; then
    log "WARN: repo default_branch='$default_branch' differs from configured ref='$FONTS_REPO_REF' (continuing with '$FONTS_REPO_REF')"
  fi

  if [[ -f "$REPO_PUSHED_AT_FILE" ]]; then
    local last_pushed
    last_pushed="$(cat "$REPO_PUSHED_AT_FILE" 2>/dev/null || true)"
    if [[ "$last_pushed" == "$pushed_at" ]]; then
      log "Repo pushed_at unchanged ($pushed_at). Skipping archive download/extract; cache sync assumed up-to-date."
      return 0
    fi
  fi

  log "Repo changed (pushed_at=$pushed_at). Downloading tarball for ref '$FONTS_REPO_REF'..."
  local tar_url="https://api.github.com/repos/${FONTS_REPO_OWNER}/${FONTS_REPO_NAME}/tarball/${FONTS_REPO_REF}"

  # Download to a temp file then atomically replace archive cache
  local tmp_archive
  tmp_archive="$(mktemp "${TMPDIR_BASE%/}/fonts_repo.XXXXXX.tar.gz")"
  curl -fSL \
    -H "Accept: application/vnd.github+json" \
    -H "User-Agent: dotfiles-fonts-sync" \
    -o "$tmp_archive" \
    "$tar_url" || die "Failed to download tarball"

  mv -f "$tmp_archive" "$ARCHIVE_CACHE_FILE"

  # Extract
  local tmp_extract
  tmp_extract="$(mktemp -d "${TMPDIR_BASE%/}/fonts_extract.XXXXXX")"
  trap 'rm -rf "$tmp_extract" 2>/dev/null || true' RETURN

  log "Extracting tarball..."
  tar -xzf "$ARCHIVE_CACHE_FILE" -C "$tmp_extract" || die "Failed to extract tarball"

  # GitHub tarballs contain a single top-level directory like: owner-repo-sha/
  local extracted_root
  extracted_root="$(find "$tmp_extract" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  [[ -n "$extracted_root" ]] || die "Could not find extracted root directory"

  log "Syncing fonts into cache dir: $DOTFILES_FONTS_DIR (add/update only; no deletions)"
  # rsync without "--delete" does not remove local files
  # shellcheck disable=SC2046
  rsync -a \
    $(build_rsync_font_filters) \
    "$extracted_root"/ \
    "$DOTFILES_FONTS_DIR"/

  printf '%s\n' "$pushed_at" >"$REPO_PUSHED_AT_FILE"
  log "Cache sync complete."
}

install_fonts_macos() {
  need_cmd rsync
  local target="$HOME/Library/Fonts"
  mkdir -p "$target"

  log "Installing fonts for current user (macOS) -> $target"
  # shellcheck disable=SC2046
  rsync -a \
    $(build_rsync_font_filters) \
    "$DOTFILES_FONTS_DIR"/ \
    "$target"/

  # macOS typically picks up fonts automatically; no mandatory cache refresh.
}

install_fonts_linux() {
  need_cmd rsync

  if [[ "$DOTFILES_FORCE_FONTS_INSTALL" == "1" ]]; then
    log "Linux: DOTFILES_FORCE_FONTS_INSTALL=1 set; forcing installation."
  else
    if is_vm_linux; then
      log "Linux: VM detected (or unknown). Skipping font installation (set DOTFILES_FORCE_FONTS_INSTALL=1 to override)."
      return 0
    fi
    log "Linux: bare metal detected; proceeding with installation."
  fi

  local target="$HOME/.local/share/fonts"
  mkdir -p "$target"

  log "Installing fonts for current user (Linux) -> $target"
  # shellcheck disable=SC2046
  rsync -a \
    $(build_rsync_font_filters) \
    "$DOTFILES_FONTS_DIR"/ \
    "$target"/

  if command -v fc-cache >/dev/null 2>&1; then
    log "Refreshing fontconfig cache (fc-cache -f)..."
    fc-cache -f >/dev/null 2>&1 || log "WARN: fc-cache failed (continuing)"
  else
    log "WARN: fc-cache not found; skipping font cache refresh."
  fi
}

main() {
  # If DOTFILES_ROOT is set, normalize it
  DOTFILES_ROOT="$(cd -- "$DOTFILES_ROOT" && pwd)"
  DOTFILES_FONTS_DIR="${DOTFILES_FONTS_DIR/#\$DOTFILES_ROOT/$DOTFILES_ROOT}"

  log "DOTFILES_ROOT=$DOTFILES_ROOT"
  log "DOTFILES_FONTS_DIR=$DOTFILES_FONTS_DIR"
  log "Repo=${FONTS_REPO_OWNER}/${FONTS_REPO_NAME} ref=$FONTS_REPO_REF"

  sync_fonts_cache

  if is_macos; then
    install_fonts_macos
  elif is_linux; then
    install_fonts_linux
  else
    log "Unsupported OS ($(uname -s)); sync completed, skipping installation."
  fi

  log "Done."
}

main "$@"
