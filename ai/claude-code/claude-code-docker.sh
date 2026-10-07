#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'
# Run the ai/claude-code Docker image against the current directory.
#
# More flexible than docker compose for this single-container use case:
#   - forwards ANTHROPIC_API_KEY to the container only if it's set on the
#     host (opt-in metered billing); otherwise Claude Code logs into your
#     Claude.ai subscription via its normal browser flow, same as natively
#   - mounts the current directory at its own real host path (not a fixed
#     /workspace) - see the WORKSPACE_DIR comment below for why
#   - accepts extra host directories to mount as CLI arguments
#   - reads a project-local config file for per-project settings (below)
#
# Usage:
#   ai/claude-code/claude-code-docker.sh [-e NAME | -e NAME=value ...] [-r SESSION_ID] [host_path:container_path ...]
#
# Positional arguments are extra host directories to bind-mount, each as
# "host_path:container_path" (host_path may start with ~). Every one of them
# also gets a matching `claude --add-dir container_path`, since Claude Code
# scopes file-tool access to declared directories independently of what the
# container itself can reach - a bind mount alone isn't enough for Claude to
# read/write it. -e/--env (repeatable, see "env:" below) works the same as
# on the CLI as it does in config, and can appear before, after, or mixed in
# with the positional mount arguments.
#
# -r/--resume SESSION_ID (a value is required - see below) resumes a
# previous `claude` conversation instead of starting a new one; it's
# forwarded to the inner `claude` invocation as `--resume SESSION_ID`.
# Session transcripts (~/.claude/projects/<cwd>/<session-id>.jsonl) and
# ~/.claude.json's per-project record both already live under the ~/.claude
# bind mount this script persists across --rm runs (see STATE_DIR below), so
# a session from an earlier run of the same project directory is already
# there to resume - no extra mount is needed to support this.
# Unlike native claude, bare `--resume`/`-r` with no value (which opens an
# interactive picker across every session claude can see) is NOT supported
# here - a value is always required, to keep this wrapper's CLI parsing
# unambiguous against the positional mount arguments above without needing
# lookahead heuristics. A SESSION_ID belonging to a different project
# directory correctly fails to resume (claude reports it as not found),
# since each project directory gets its own session bucket - see the
# WORKSPACE_DIR comment below.
#
# ── Project config: .aiproj / .aiproj.yaml / .aiproj.yml ─────────────────────
# The first of these found in the current directory is read (they are NOT
# merged with each other - pick one). In addition, an .aiproj.local file
# alongside it - meant to be gitignored, for machine-local values such as a
# literal secret or a host-specific volume - is ALSO read whenever it
# exists, independently of whether a primary config file was found. Every
# list below is the concatenation of both files (primary file's items first,
# then .aiproj.local's), not a replace-the-whole-list override.
#
# yq, when installed, parses all of this properly. Without it, a minimal
# fallback line-parser handles the flat "key:\n  - item" list format shown
# below (one list per top-level key, plain scalars, "#" trailing comments
# and matching quotes stripped) - anything fancier (nested maps, multi-line
# values, YAML anchors, ...) needs yq.
#
#   volumes:              # extra host directories to bind-mount, same
#     - ~/repos:/repos    # "host_path:container_path" form as CLI args, and
#                         # also get an --add-dir the same way
#
#   install:              # project dependencies baked into a derived image,
#                         # since the container runs as an arbitrary host
#                         # uid with no root - nothing can be installed at
#                         # run time - it all has to be an image layer.
#                         # Each entry is EITHER:
#     - postgresql-client #   - a plain apt package name (anything with no
#                         #     recipe below), apt-installed as-is; or
#     - uv                #   - one of a small built-in recipe registry (see
#                         #     _recipe_dockerfile) for tools apt doesn't
#                         #     package or ships too stale a version of,
#                         #     which may also need extra ENV/cache setup
#                         #     that a plain "apt install" wouldn't provide.
#                         # Recipes today: uv, docker-cli (see docker: below
#                         # - you normally don't list docker-cli yourself).
#                         # Entries must match ^[a-z0-9][a-z0-9+.-]*$ (valid
#                         # apt package name shape); anything else is
#                         # rejected before it reaches a Dockerfile. Unknown
#                         # non-recipe names still go to apt and fail there
#                         # with apt's own "Unable to locate package" error.
#                         #
#                         # The derived image is tagged
#                         # ai-claude-code-proj:<hash of base tag + sorted
#                         # apt list + sorted recipe list>, and only rebuilt
#                         # when that hash is new - an unchanged project
#                         # starts instantly, while a new Claude Code base
#                         # image (new version, or a bumped BUILD) yields a
#                         # new hash and triggers exactly one rebuild. Old
#                         # project-tagged images are NOT pruned automatically
#                         # as they age out; `docker image prune` / `docker
#                         # rmi ai-claude-code-proj:...` by hand if they
#                         # accumulate.
#
#   env:                  # env vars for the container; each entry is
#                         # EITHER:
#     - GITHUB_TOKEN      #   - a bare NAME (no "="): passes the HOST's
#                         #     current value through via plain `docker run
#                         #     -e NAME` - this script itself never reads,
#                         #     logs, or stores that value, so it can't leak
#                         #     it. If NAME isn't set on the host at run
#                         #     time, it's silently skipped with a logged
#                         #     warning (naming the var, never a value).
#     - APP_MODE=dev      #   - a NAME=value literal, written to a mode-0600
#                         #     --env-file (removed again on exit via the
#                         #     same trap that cleans up the gitconfig temp
#                         #     file) rather than passed as a -e argument, so
#                         #     the value never appears in argv/`ps` output.
#                         # Entries from config and any CLI -e/--env flags
#                         # are all applied in order (config first, then
#                         # CLI), so a later entry for the same NAME wins -
#                         # in particular, a CLI -e overrides a same-named
#                         # config entry. NAME must be a valid shell
#                         # identifier ([A-Za-z_][A-Za-z0-9_]*); anything
#                         # else is rejected.
#                         # Security note: anything passed this way is
#                         # readable by Claude and by anything it runs
#                         # inside the container, which has normal internet
#                         # access - pass narrowly-scoped tokens, not broad
#                         # credentials, and treat this the same as any other
#                         # secret exposed to an agent with shell access.
#
#   docker: true          # Lets Claude run `docker`/`docker compose` INSIDE
#                         # the container against the HOST's own Docker
#                         # engine (installs the docker-cli recipe
#                         # automatically - the client + compose plugin only;
#                         # it expects a working engine + daemon already on
#                         # the host, e.g. for Postgres via
#                         # `docker run`/compose rather than a built-in
#                         # "services:" config option - there isn't one).
#                         # Mechanism: bind-mounts the host's Docker socket
#                         # (/var/run/docker.sock - the default Linux/Docker
#                         # Desktop location; a non-default socket, e.g.
#                         # under Colima or a rootless dockerd, isn't
#                         # detected and needs the script adjusted) and joins
#                         # its group so the container's host-uid user can
#                         # reach it.
#                         # This is ROOT-EQUIVALENT on the host: anything
#                         # started through that socket runs as a peer of
#                         # every other container on the host, can mount any
#                         # host path, and isn't sandboxed by this script in
#                         # any way - a warning is logged every run as a
#                         # reminder. Opt in per project deliberately.
#                         # Because containers started this way are created
#                         # by the HOST daemon, any bind-mount source path
#                         # they use resolves on the HOST's filesystem, not
#                         # inside this container - this is one of the two
#                         # reasons the workspace is always mounted at its
#                         # real host path rather than a fixed /workspace
#                         # (see the WORKSPACE_DIR comment below), so a
#                         # docker-compose.yml's "./:/app"-style mount inside
#                         # it lines up correctly. That real-path mount only
#                         # covers the workspace itself, though: "volumes:"
#                         # entries and CLI-mounted extra directories keep
#                         # whatever container-side path they were given and
#                         # do NOT get host-path-equivalent treatment, so a
#                         # container spawned via this socket generally
#                         # can't usefully bind-mount one of those unless its
#                         # container path happens to equal its host path.
#
#   worktrees: true      # Makes the Git worktree topology (see bin/worktrees.sh)
#                         # valid inside the container while keeping each
#                         # agent scoped to its own checkout. Both mounts are
#                         # at the same absolute path as on the host, since
#                         # git stores absolute paths between a repo and its
#                         # worktrees:
#                         #   - launched from the MAIN repo: mounts
#                         #     $WORKTREES_DIR/<repo> (default
#                         #     ~/worktrees/<repo>, created if missing), so
#                         #     the task worktrees exist in the container
#                         #     (git would otherwise see them as stale and
#                         #     `git worktree prune` could drop them) and
#                         #     are readable to Claude (--add-dir). The mount
#                         #     is deliberately read-write: this is the
#                         #     integration container, which runs `rebase`,
#                         #     `done` and `cleanup` on task worktrees
#                         #     (rewriting files / deleting directories).
#                         #   - launched from a LINKED worktree: mounts only
#                         #     the repo's git common dir (`git rev-parse
#                         #     --git-common-dir`), which git needs for
#                         #     refs/objects/config. The main working tree is
#                         #     NOT mounted, and the git dir is plumbing, not
#                         #     an --add-dir: integration into the base
#                         #     branch stays with the main/integration
#                         #     workflow (`worktrees.sh done`).
#                         # Note the common dir is mounted read-write (git
#                         # writes there), including .git/hooks and config.
#                         # No-op outside a git repo.
#
# Builds the image automatically the first time it's needed for the current
# ai/claude-code/BUILD number, tagged <claude_code_version>.<build_number>
# (e.g. 2.1.270.1) - the Claude Code version is resolved from
# downloads.claude.ai and pinned into the build so it's reproducible, rather
# than the image silently drifting to whatever Claude Code ships next.
# Bump BUILD and re-run after changing the Dockerfile/entrypoint to force a
# fresh build (which also picks up whatever Claude Code version is current
# at that time). Independently of BUILD, downloads.claude.ai is also
# re-checked at most once a day (stamped in a temp file) and the image is
# rebuilt if a newer Claude Code version is available - see below. (The
# "install:"/"docker:" derived image above is a second, separate layer on
# top of this one, retagged and rebuilt independently per the rules above.)
#
# Runs claude with --permission-mode auto (a classifier judges each action
# against Claude Code's built-in allow/soft_deny/hard_deny rules, rather than
# prompting for everything beyond file edits the way acceptEdits does) plus
# --add-dir for every mounted folder beyond the primary workspace mount,
# since Claude Code scopes file-tool access to declared directories
# independently of what the container itself can reach.
#
# Also, so each run isn't a fresh install:
#   - persists Claude Code's own state (onboarding/trust/theme/settings)
#     across --rm runs, in $XDG_STATE_HOME/ai-claude-code (or
#     ~/.local/state/ai-claude-code)
#   - persists uv's package cache the same way, under the same state
#     directory, whenever the uv recipe is in play (directly listed under
#     install:, or pulled in by another recipe) - otherwise every fresh
#     --rm container would re-download packages uv already fetched before
#   - passes TZ through from the host so container time matches local time

dotdir="$(cd "$(dirname "$0")/../.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

IMAGE_DIR="$dotdir/ai/claude-code"
IMAGE_NAME="ai-claude-code"
BUILD_N="$(<"$IMAGE_DIR/BUILD")"
CONFIG_CANDIDATES=(".aiproj" ".aiproj.yaml" ".aiproj.yml")

# Reuse whatever image is already tagged for this BUILD number - picking the
# highest Claude Code version if more than one is somehow tagged for it -
# then decide whether it's still worth asking downloads.claude.ai for
# something newer. That check only actually runs (a) when no image exists
# yet for this BUILD number at all, or (b) at most once a day otherwise,
# tracked via a per-user stamp file in the temp dir (so a reboot, a cleared
# /tmp, or a new day all naturally trigger a re-check). This keeps every
# other run - already checked today - network-independent.
IMAGE_TAG="$(docker images "$IMAGE_NAME" --format '{{.Repository}}:{{.Tag}}' 2>/dev/null \
  | grep -E "^${IMAGE_NAME}:[0-9]+\.[0-9]+\.[0-9]+\.${BUILD_N}\$" \
  | sort -t: -k2 -V | tail -n1)"

VERSION_CHECK_STAMP="${TMPDIR:-/tmp}/ai-claude-code-version-check-$(id -u)"
_today="$(date +%Y-%m-%d)"
_last_checked="$(cat "$VERSION_CHECK_STAMP" 2>/dev/null || true)"

if [ -z "$IMAGE_TAG" ] || [ "$_last_checked" != "$_today" ]; then
  if [ -z "$IMAGE_TAG" ]; then
    log_info "No image found for build ${BUILD_N}; resolving current Claude Code version ..."
  else
    log_trace "Daily check: resolving current Claude Code version (last checked ${_last_checked:-never}) ..."
  fi

  claude_code_version="$(curl -fsSL https://downloads.claude.ai/claude-code-releases/latest)"
  if [[ "$claude_code_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # Only stamp today's date on a successful check - a network hiccup
    # should retry next run, not silently wait out the rest of the day.
    echo "$_today" >"$VERSION_CHECK_STAMP"
    _resolved_tag="${IMAGE_NAME}:${claude_code_version}.${BUILD_N}"
    if [ "$_resolved_tag" != "$IMAGE_TAG" ]; then
      log_info "${IMAGE_TAG:+Newer Claude Code version found; }Building ${_resolved_tag} ..."
      docker build --build-arg CLAUDE_CODE_VERSION="$claude_code_version" \
        -t "$_resolved_tag" -t "${IMAGE_NAME}:latest" "$IMAGE_DIR"
      # Drop the now-superseded version tag for this BUILD number so images
      # don't quietly pile up on every upstream release; best-effort only,
      # e.g. a container still using it shouldn't block this run.
      [ -n "$IMAGE_TAG" ] && docker rmi "$IMAGE_TAG" >/dev/null 2>&1
      IMAGE_TAG="$_resolved_tag"
    fi
  elif [ -z "$IMAGE_TAG" ]; then
    log_error "claude-code-docker.sh: couldn't resolve the current Claude Code version (got \"${claude_code_version}\")."
    exit 1
  else
    log_warning "claude-code-docker.sh: couldn't check for a newer Claude Code version (got \"${claude_code_version}\"); using cached image ${IMAGE_TAG}."
  fi
fi

_gitconfig_tmp=""
_env_file=""
_cleanup() { rm -f "$_gitconfig_tmp" "$_env_file"; }
trap _cleanup EXIT

# ── Command line ─────────────────────────────────────────────────────────────
# -r/--resume <session-id> resumes a previous `claude` conversation instead
# of starting a new one, forwarded as `claude ... --resume <session-id>`
# below. Its transcript (~/.claude/projects/<cwd>/<session-id>.jsonl) and
# ~/.claude.json's per-project record both live under the ~/.claude bind
# mount this script already persists (see STATE_DIR below), so a session
# from an earlier run of this same project directory is already there to
# resume - no extra mount needed. A value is always required (unlike native
# claude, where --resume alone opens an interactive picker across every
# session claude can see): this wrapper doesn't support the bare/picker
# form, both to keep CLI parsing unambiguous against the positional mount
# arguments below, and because every project run without docker: true
# currently shares one project bucket (see the WORKSPACE_DIR/docker: true
# comment above) - a picker there would list unrelated projects' sessions
# together, not just this one's.
CLI_ENV=()
CLI_MOUNTS=()
RESUME_ID=""
# Shared by both --resume forms below: a session ID that looks like a flag
# means the next argument was swallowed by mistake (e.g. a missing value).
_validate_resume_id() {
  if [[ "$RESUME_ID" == -* ]]; then
    log_error "claude-code-docker.sh: --resume value \"${RESUME_ID}\" looks like a flag, not a session ID."
    exit 1
  fi
}
while [ $# -gt 0 ]; do
  case "$1" in
    -e | --env)
      if [ $# -lt 2 ]; then
        log_error "claude-code-docker.sh: $1 needs a NAME or NAME=value argument."
        exit 1
      fi
      CLI_ENV+=("$2")
      shift 2
      ;;
    --env=*)
      CLI_ENV+=("${1#--env=}")
      shift
      ;;
    -r | --resume)
      if [ $# -lt 2 ]; then
        log_error "claude-code-docker.sh: $1 needs a session-id argument (the bare/picker form isn't supported - see the script header)."
        exit 1
      fi
      RESUME_ID="$2"
      _validate_resume_id
      shift 2
      ;;
    --resume=*)
      RESUME_ID="${1#--resume=}"
      if [ -z "$RESUME_ID" ]; then
        log_error "claude-code-docker.sh: $1 needs a session-id argument (the bare/picker form isn't supported - see the script header)."
        exit 1
      fi
      _validate_resume_id
      shift
      ;;
    *)
      CLI_MOUNTS+=("$1")
      shift
      ;;
  esac
done

# ── Project config (.aiproj[.yaml|.yml] + optional .aiproj.local) ───────────
# Trims trailing " # comment", surrounding whitespace and matching quotes
# from a list item (fallback parser only; yq does this natively).
_strip_item() {
  local v="$1"
  v="$(printf '%s' "$v" | sed -E 's/[[:space:]]+#.*$//; s/^[[:space:]]+//; s/[[:space:]]+$//')"
  if [[ "$v" =~ ^\"(.*)\"$ ]] || [[ "$v" =~ ^\'(.*)\'$ ]]; then
    v="${BASH_REMATCH[1]}"
  fi
  printf '%s\n' "$v"
}

# _cfg_list <file> <key>: prints the items of a top-level list, one per line.
_cfg_list() {
  local file="$1" key="$2" line val in_list=false
  if _has yq; then
    yq -r ".${key}[]?" "$file" 2>/dev/null
    return 0
  fi
  # Minimal fallback for the flat "key:\n  - item" format, used without yq.
  # The key line itself may carry a trailing "# comment" (the script's own
  # header examples are written that way, e.g. "install:  # system deps").
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^${key}:[[:space:]]*(\#.*)?$ ]]; then
      in_list=true
    elif $in_list; then
      if [[ "$line" =~ ^[[:space:]]+-[[:space:]]*(.+)$ ]]; then
        val="$(_strip_item "${BASH_REMATCH[1]}")"
        [ -n "$val" ] && printf '%s\n' "$val"
      elif [[ ! "$line" =~ ^[[:space:]]*(#.*)?$ ]]; then
        in_list=false
      fi
    fi
  done <"$file"
}

# _cfg_scalar <file> <key>: prints a top-level scalar value (empty if absent).
# YAML 1.1 boolean spellings (True/yes/on/... ) are normalized to lowercase
# true/false, since the only consumers (docker:/worktrees:) compare with
# `= "true"`.
_cfg_scalar() {
  local file="$1" key="$2" line val
  if _has yq; then
    yq -r ".${key} // \"\"" "$file" 2>/dev/null
    return 0
  fi
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^${key}:[[:space:]]*(.+)$ ]]; then
      val="$(_strip_item "${BASH_REMATCH[1]}")"
      case "$val" in
        [Tt][Rr][Uu][Ee] | [Yy][Ee][Ss] | [Oo][Nn] | 1) val="true" ;;
        [Ff][Aa][Ll][Ss][Ee] | [Nn][Oo] | [Oo][Ff][Ff] | 0) val="false" ;;
      esac
      printf '%s\n' "$val"
    fi
  done <"$file"
}

_config_files=()
for candidate in "${CONFIG_CANDIDATES[@]}"; do
  if [ -f "$candidate" ]; then
    _config_files+=("$candidate")
    break
  fi
done
if [ -f ".aiproj.local" ]; then
  _config_files+=(".aiproj.local")
fi

CFG_VOLUMES=()
CFG_INSTALL=()
CFG_ENV=()
CFG_DOCKER=false
CFG_WORKTREES=false
# "${arr[@]+"${arr[@]}"}" (used throughout this script wherever an array
# that may be empty is expanded): plain "${arr[@]}" on an empty array is an
# "unbound variable" error under `set -u` on bash <4.4 (macOS's system
# /bin/bash is 3.2); this idiom expands to nothing instead.
for _f in "${_config_files[@]+"${_config_files[@]}"}"; do
  log_trace "Reading project config: ${_f}"
  while IFS= read -r _v; do [ -n "$_v" ] && CFG_VOLUMES+=("$_v"); done < <(_cfg_list "$_f" volumes)
  while IFS= read -r _v; do [ -n "$_v" ] && CFG_INSTALL+=("$_v"); done < <(_cfg_list "$_f" install)
  while IFS= read -r _v; do [ -n "$_v" ] && CFG_ENV+=("$_v"); done < <(_cfg_list "$_f" env)
  _v="$(_cfg_scalar "$_f" docker)"
  [ -n "$_v" ] && CFG_DOCKER="$_v"
  _v="$(_cfg_scalar "$_f" worktrees)"
  [ -n "$_v" ] && CFG_WORKTREES="$_v"
done

# ── install: apt packages + built-in recipes -> derived image ────────────────
# Names with a recipe below get that recipe (for tools apt lacks or ships
# stale, plus the env/cache setup they need); everything else is an apt
# package. The container runs as an arbitrary host uid with no root, so
# nothing can be installed at run time - it has to be baked into an image.
INSTALL_APT=()
INSTALL_RECIPES=()

_uses_recipe() {
  local r
  for r in "${INSTALL_RECIPES[@]+"${INSTALL_RECIPES[@]}"}"; do
    [ "$r" = "$1" ] && return 0
  done
  return 1
}
_add_recipe() { _uses_recipe "$1" || INSTALL_RECIPES+=("$1"); }

# Dockerfile fragment (run as root) for a recipe.
_recipe_dockerfile() {
  case "$1" in
    uv)
      # System-wide (not ~/.local) so any uid can run it; its cache dir is
      # a host-owned bind mount added below, as the image's home isn't
      # writable by the host uid.
      cat <<'DFEOF'
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL=/usr/local/bin sh
ENV UV_CACHE_DIR=/home/claude/.cache/uv
DFEOF
      ;;
    docker-cli)
      # Client + compose plugin only; the engine is the host's (docker: true).
      cat <<'DFEOF'
RUN install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" >/etc/apt/sources.list.d/docker.list \
  && apt-get update -qq \
  && apt-get install -y -qq --no-install-recommends docker-ce-cli docker-compose-plugin \
  && rm -rf /var/lib/apt/lists/*
DFEOF
      ;;
  esac
}

# docker: true implies the docker-cli recipe - no need to list it.
[ "$CFG_DOCKER" = "true" ] && _add_recipe docker-cli
for _item in "${CFG_INSTALL[@]+"${CFG_INSTALL[@]}"}"; do
  # Interpolated into a Dockerfile: allow only valid package-name characters.
  if [[ ! "$_item" =~ ^[a-z0-9][a-z0-9+.-]*$ ]]; then
    log_error "claude-code-docker.sh: invalid install entry \"${_item}\" (expected an apt package name or a recipe name)."
    exit 1
  fi
  case "$_item" in
    uv | docker-cli) _add_recipe "$_item" ;;
    *) INSTALL_APT+=("$_item") ;;
  esac
done

_sha256() { if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi; }

if [ "${#INSTALL_APT[@]}" -gt 0 ] || [ "${#INSTALL_RECIPES[@]}" -gt 0 ]; then
  _apt_sorted="$(printf '%s\n' "${INSTALL_APT[@]+"${INSTALL_APT[@]}"}" | sed '/^$/d' | sort -u | tr '\n' ' ')"
  _recipes_sorted="$(printf '%s\n' "${INSTALL_RECIPES[@]+"${INSTALL_RECIPES[@]}"}" | sed '/^$/d' | sort -u | tr '\n' ' ')"
  # The hash covers the base tag, so a new base image (Claude Code release
  # or BUILD bump) yields a new project tag and a rebuild; an unchanged
  # project starts instantly.
  _proj_hash="$(printf '%s|%s|%s' "$IMAGE_TAG" "$_apt_sorted" "$_recipes_sorted" | _sha256 | cut -c1-12)"
  _proj_tag="${IMAGE_NAME}-proj:${_proj_hash}"
  if ! docker images "${IMAGE_NAME}-proj" --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -qxF "$_proj_tag"; then
    log_info "Building project image ${_proj_tag} (apt: ${_apt_sorted:-none}; recipes: ${_recipes_sorted:-none}) ..."
    _dockerfile="FROM ${IMAGE_TAG}
USER root
"
    if [ -n "$_apt_sorted" ]; then
      _dockerfile+="RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends ${_apt_sorted}&& rm -rf /var/lib/apt/lists/*
"
    fi
    while IFS= read -r _r; do
      [ -n "$_r" ] && _dockerfile+="$(_recipe_dockerfile "$_r")
"
    done < <(printf '%s\n' "${INSTALL_RECIPES[@]+"${INSTALL_RECIPES[@]}"}" | sed '/^$/d' | sort -u)
    _dockerfile+="USER claude
"
    if ! printf '%s' "$_dockerfile" | docker build -t "$_proj_tag" -; then
      log_error "claude-code-docker.sh: building the project image failed."
      exit 1
    fi
  fi
  IMAGE_TAG="$_proj_tag"
fi

# The workspace is mounted at its own real host path (e.g.
# /home/you/homelab), not a fixed /workspace, for two independent reasons:
#   - Claude Code keys everything project-scoped - session transcripts
#     (~/.claude/projects/<cwd-with-/-as-->/<id>.jsonl) and per-project
#     settings in ~/.claude.json (trust dialog, allowed tools, MCP servers)
#     - by the literal container cwd string. A fixed /workspace would make
#     every project this script is ever run against look like the SAME
#     project to Claude Code, sharing one another's session history and
#     settings; a real, distinct-per-project path keeps them isolated,
#     matching how native (non-Docker) claude already behaves per directory.
#     (This is a separate, container-local ~/.claude store, though - see
#     STATE_DIR below - so it doesn't merge with a host-native claude
#     install's own history even when the path happens to match.)
#   - With docker: true, bind-mount sources in `docker`/`docker compose`
#     commands run inside the container resolve on the HOST, so the project
#     must be visible at its real host path or e.g. `.:/app` would mount the
#     wrong directory (see the docker: true entry above).
WORKSPACE_DIR="$(pwd)"
WORKSPACE_MOUNT="$(pwd):${WORKSPACE_DIR}"

docker_args=(run --rm)

if [ -t 0 ] && [ -t 1 ]; then
  docker_args+=(-it)
else
  docker_args+=(-i)
fi

docker_args+=(
  -v "$WORKSPACE_MOUNT"
  -w "$WORKSPACE_DIR"
  # Run as the host's own uid:gid, not the image's baked-in claude user, so
  # writes to the host-owned state directories mounted below (persistence)
  # actually succeed instead of silently failing on a uid mismatch — see
  # the Dockerfile's matching comment for why that mismatch happens at all.
  --user "$(id -u):$(id -g)"
  # Without a correct TERM, Claude Code can misdetect terminal capabilities
  # (including which clipboard integration path to use).
  -e "TERM=${TERM:-xterm-256color}"
)

# Only forward ANTHROPIC_API_KEY if it's actually set in the host shell -
# it's deliberately not required. Setting it switches Claude Code to
# pay-per-token API billing (credits) instead of a logged-in Claude.ai
# subscription (Pro/Max/Team), which is almost certainly not what you want
# for everyday use. Leave it unset and Claude Code falls back to its normal
# browser-based account login on first run inside the container, same as a
# native install; that login persists into $STATE_DIR/claude/.credentials.json
# below (already covered by the ~/.claude bind mount, no extra mount needed)
# so you only log in once. Only export ANTHROPIC_API_KEY before running this
# script if you specifically want metered API billing for this session.
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  docker_args+=(-e "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}")
fi

# docker: true - let the container drive the host's Docker engine (CLI and
# compose plugin come from the docker-cli recipe). This mounts the host
# socket, which is root-equivalent on the host: Claude can start privileged
# containers and mount any host path. Opt-in per project for that reason.
if [ "$CFG_DOCKER" = "true" ]; then
  _sock=/var/run/docker.sock
  if [ ! -S "$_sock" ]; then
    log_error "claude-code-docker.sh: docker: true needs the host Docker socket at ${_sock}."
    exit 1
  fi
  log_warning "claude-code-docker.sh: docker: true gives the container full control of the host Docker engine (root-equivalent)."
  docker_args+=(-v "${_sock}:${_sock}")
  # The container runs as the host uid, so join the socket's group to reach it.
  _sock_gid="$(stat -c %g "$_sock" 2>/dev/null || stat -f %g "$_sock" 2>/dev/null || true)"
  [ -n "$_sock_gid" ] && docker_args+=(--group-add "$_sock_gid")
fi

# env: NAME passes the host's value through (docker reads it itself from
# `-e NAME` - this script never expands, logs or stores it); NAME=value is a
# literal, written to a 0600 env-file rather than argv so it stays out of
# `ps`. Config entries are recorded first, then CLI entries, into these two
# parallel (plain, bash-3.2-friendly) arrays keyed by position -- a repeat of
# the same name overwrites its earlier slot in place, so a later (CLI) entry
# always wins over an earlier (config) one regardless of which side used
# which kind. Resolving the winner ourselves (rather than emitting both a
# `-e NAME` and an `--env-file` line and letting docker pick) means the "CLI
# wins" contract holds even when config and CLI mix bare vs literal for the
# same name.
_ENV_NAMES=()
_ENV_ENTRIES=()
_add_env() {
  local entry="$1" name i
  name="${entry%%=*}"
  if [[ ! "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    log_error "claude-code-docker.sh: invalid env entry name \"${name}\"."
    exit 1
  fi
  for i in "${!_ENV_NAMES[@]}"; do
    if [ "${_ENV_NAMES[i]}" = "$name" ]; then
      _ENV_ENTRIES[i]="$entry"
      return 0
    fi
  done
  _ENV_NAMES+=("$name")
  _ENV_ENTRIES+=("$entry")
}
for _e in "${CFG_ENV[@]+"${CFG_ENV[@]}"}" "${CLI_ENV[@]+"${CLI_ENV[@]}"}"; do
  _add_env "$_e"
done
for _i in "${!_ENV_NAMES[@]}"; do
  _name="${_ENV_NAMES[_i]}"
  _entry="${_ENV_ENTRIES[_i]}"
  if [[ "$_entry" == *=* ]]; then
    [ -n "$_env_file" ] || _env_file="$(mktemp)"
    printf '%s\n' "$_entry" >>"$_env_file"
  elif [ -n "${!_name+x}" ]; then
    docker_args+=(-e "$_name")
  else
    log_warning "claude-code-docker.sh: env ${_name} is not set on the host; not passing it."
  fi
done
[ -n "$_env_file" ] && docker_args+=(--env-file "$_env_file")

# Claude Code's fullscreen TUI (enabled by default in this image) captures
# mouse events for its own use — including, when it detects $TMUX, writing
# a mouse selection straight to the tmux clipboard buffer ("Copied N chars
# to tmux buffer"), which this repo's own tmux config then mirrors out to
# the host clipboard via OSC 52. That only works if the container can reach
# the *same* tmux server: bridge its socket and $TMUX through when present.
# Without tmux to bridge through, mouse capture just hijacks the terminal's
# native click-and-drag selection with nowhere for it to go — disable mouse
# clicks instead so that native selection (and whatever clipboard handling
# your terminal does on its own) works, at the cost of click/drag/hover
# within Claude Code itself; scroll-wheel support is unaffected either way.
if [ -n "${TMUX:-}" ] && [ -S "${TMUX%%,*}" ]; then
  docker_args+=(-e "TMUX=${TMUX}" -v "${TMUX%%,*}:${TMUX%%,*}")
  # Also name the pane. tmux sets $TMUX_PANE, and a host-side tool watching
  # this container (ccmux) can read it from the container process's environ:
  # the container's own tty number (pts/0, in its private devpts) can't be
  # matched against host panes, so this is how it knows which pane hosts it.
  [ -n "${TMUX_PANE:-}" ] && docker_args+=(-e "TMUX_PANE=${TMUX_PANE}")
else
  docker_args+=(-e "CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1")
fi

# ccmux (a tmux agent-session tracker) learns an agent's state from marker
# files that Claude Code hooks write into <CCMUX_HOME or ~/.config/ccmux>/
# session-pids. The hooks run inside this container, so share that directory
# (at the container user's default location, where the hook looks) or the
# session would never show up. Only when ccmux is set up on the host - the
# directory is created by it - so this stays out of the way for everyone else.
_ccmux_markers="${CCMUX_HOME:-$HOME/.config/ccmux}/session-pids"
if [ -d "$_ccmux_markers" ]; then
  docker_args+=(-v "${_ccmux_markers}:/home/claude/.config/ccmux/session-pids")
fi
unset _ccmux_markers

# Pass through the host's effective git identity (user.name / user.email,
# resolved the same way any git command run outside Docker would resolve
# them for this directory - i.e. respecting a repo-local override) as a
# minimal global .gitconfig inside the container, so Claude can create
# commits without extra setup. Written as a *global* config, not
# GIT_AUTHOR_NAME/EMAIL env vars, so precedence still matches normal git
# behavior: the mounted repo's own local config (e.g. a per-project identity
# override) continues to win over this default, whereas env vars would
# incorrectly override even that. Only user.name/email are propagated -
# deliberately not the rest of the host's ~/.gitconfig (credential helpers,
# GPG signing, core.editor, etc.), since those commonly point at host-only
# binaries/keys that don't exist in this ephemeral container and would
# break git operations rather than help them. Regenerated fresh on every
# run (not persisted in STATE_DIR below) so it always reflects the host's
# current config.
_git_user_name="$(git config user.name 2>/dev/null || true)"
_git_user_email="$(git config user.email 2>/dev/null || true)"
if [ -n "$_git_user_name" ] || [ -n "$_git_user_email" ]; then
  _gitconfig_tmp="$(mktemp)"
  {
    echo "[user]"
    [ -n "$_git_user_name" ] && printf '\tname = %s\n' "$_git_user_name"
    [ -n "$_git_user_email" ] && printf '\temail = %s\n' "$_git_user_email"
  } >"$_gitconfig_tmp"
  docker_args+=(-v "$_gitconfig_tmp:/home/claude/.gitconfig:ro")
else
  log_warning "claude-code-docker.sh: no git user.name/email configured on the host; commits made inside the container won't have an author identity unless set manually."
fi

# Match the container's clock to the host's (the image otherwise defaults to
# UTC). /etc/localtime is a symlink into the IANA zoneinfo tree on both
# Linux and macOS, so this works cross-platform without relying on
# Linux-only tools like /etc/timezone or timedatectl.
_host_tz="$(readlink /etc/localtime 2>/dev/null | sed -n 's#.*/zoneinfo/##p')"
if [ -n "$_host_tz" ]; then
  docker_args+=(-e "TZ=${_host_tz}")
fi

# Persist Claude Code's own state (onboarding/trust-dialog/theme, in
# ~/.claude.json; settings/plugins/custom-themes in ~/.claude/) across --rm
# runs. Kept separate from any host Claude Code install — its own state
# directory, not shared with $HOME/.claude(.json). /home/claude must match
# the image's CLAUDE_USER (Dockerfile ARG, default "claude").
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ai-claude-code"
mkdir -p "$STATE_DIR/claude"
# An empty file isn't valid JSON — claude.json must start as "{}", or
# Claude Code fails immediately with "JSON Parse error: Unexpected EOF".
[ -s "$STATE_DIR/claude.json" ] || echo '{}' >"$STATE_DIR/claude.json"
docker_args+=(
  -v "$STATE_DIR/claude.json:/home/claude/.claude.json"
  -v "$STATE_DIR/claude:/home/claude/.claude"
)
if _uses_recipe uv; then
  mkdir -p "$STATE_DIR/uv-cache"
  docker_args+=(-v "$STATE_DIR/uv-cache:/home/claude/.cache/uv")
fi

# CLAUDE_ADD_DIRS tracks the container-side path of every mount beyond the
# primary workspace mount, so Claude Code's own directory scoping (via
# --add-dir) matches exactly what's bind-mounted into the container.
CLAUDE_ADD_DIRS=()

_mount_extra_dir() {
  docker_args+=(-v "$1")
  local _rest="${1#*:}"
  CLAUDE_ADD_DIRS+=("${_rest%%:*}")
}

for extra_dir in "${CLI_MOUNTS[@]+"${CLI_MOUNTS[@]}"}"; do
  extra_dir="${extra_dir/#\~/$HOME}"
  log_trace "Mounting extra directory (CLI): ${extra_dir}"
  _mount_extra_dir "$extra_dir"
done

for _vol in "${CFG_VOLUMES[@]+"${CFG_VOLUMES[@]}"}"; do
  _vol="${_vol/#\~/$HOME}"
  log_trace "Mounting extra directory (config): ${_vol}"
  _mount_extra_dir "$_vol"
done

# worktrees: true - see the header comment. Same-path mounts, because git
# records absolute host paths in both directions (.git file <-> .git/worktrees).
if [ "$CFG_WORKTREES" = "true" ]; then
  if _git_dir="$(git rev-parse --path-format=absolute --git-dir 2>/dev/null)"; then
    _common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
    if [ "$_git_dir" != "$_common_dir" ]; then
      # Linked worktree: git needs the common dir, not the main working tree.
      # Infrastructure only - deliberately no --add-dir.
      log_trace "Mounting git common dir (worktrees): ${_common_dir}"
      docker_args+=(-v "${_common_dir}:${_common_dir}")
    else
      # Main repo: expose the task worktrees. Named after the main working
      # tree, as bin/worktrees.sh does.
      _wt_root="$(git worktree list --porcelain | sed -n '1s/^worktree //p')"
      _wt_dir="${WORKTREES_DIR:-$HOME/worktrees}/${_wt_root##*/}"
      mkdir -p -- "$_wt_dir"
      _wt_dir="$(cd -P -- "$_wt_dir" && pwd -P)"
      log_trace "Mounting task worktrees (worktrees): ${_wt_dir}"
      _mount_extra_dir "${_wt_dir}:${_wt_dir}"
    fi
  else
    log_warning "claude-code-docker.sh: worktrees: true but ${WORKSPACE_DIR} is not a git repository; ignoring."
  fi
fi

docker_args+=("$IMAGE_TAG" claude --permission-mode auto)
for add_dir in "${CLAUDE_ADD_DIRS[@]+"${CLAUDE_ADD_DIRS[@]}"}"; do
  docker_args+=(--add-dir "$add_dir")
done
# Validated at parse time (above), before any slow image build runs.
[ -n "$RESUME_ID" ] && docker_args+=(--resume "$RESUME_ID")

log_info "Launching ${IMAGE_TAG} ..."
docker "${docker_args[@]}"
