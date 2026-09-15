# Claude Code CLI sandbox image.
#
# Installs Claude Code via its native installer (no Node/npm dependency) and
# embeds rtk (Rust Token Killer, https://github.com/rtk-ai/rtk) with its
# Claude Code hook active by default for token savings. Intended to be run
# via ai/claude-code/claude-code-docker.sh, which builds this image on first
# use and mounts a project directory at /workspace.
#
# Image tag = <claude_code_version>.<build_number>, e.g. 2.1.270.1:
#   - the first three numbers are the exact Claude Code CLI version pinned
#     into this build via CLAUDE_CODE_VERSION (below) — resolved by
#     claude-code-docker.sh from downloads.claude.ai before building, so the
#     tag is known upfront and the build is reproducible (same args in,
#     same image out), rather than always silently installing "latest".
#   - the fourth number is the BUILD file alongside this Dockerfile, bumped
#     by hand whenever this image's own recipe changes (packages, tweaks,
#     etc.) — bump it and re-run claude-code-docker.sh to force a fresh
#     build (which also picks up whatever Claude Code version is latest at
#     that time).
#
# Build (normally automatic):
#   docker build --build-arg CLAUDE_CODE_VERSION=<x.y.z> \
#     -t ai-claude-code:<x.y.z>.$(cat BUILD) ai/claude-code
# Run: ai/claude-code/claude-code-docker.sh
#
# tzdata is installed so the TZ env var (set by claude-code-docker.sh from
# the host's timezone) is honored; without it glibc/date would silently
# stay on UTC regardless of TZ.
#
# claude-code-docker.sh also runs the container as the host's uid:gid (not
# this image's baked-in claude user, whose uid ubuntu:24.04's pre-existing
# "ubuntu" user at uid 1000 usually pushes to 1001) so it can actually write
# to the host-owned state directories it bind-mounts onto ~/.claude(.json)
# for persistence — a uid mismatch there fails writes silently (reads still
# succeed, since those files stay world-readable). HOME is set explicitly
# above since that --user override has no /etc/passwd entry for Docker to
# infer it from.
#
# tmux is installed so that, when claude-code-docker.sh is itself run from
# inside a host tmux session, Claude Code's own tmux-aware clipboard
# integration (mouse selection -> "Copied N chars to tmux buffer") works the
# same as it does natively: the script bridges the host's tmux server socket
# and $TMUX into the container so this image's tmux client can reach it.

FROM ubuntu:24.04

ARG CLAUDE_USER=claude
# Pinned by claude-code-docker.sh to the exact version it resolved before
# building, so the image (and its tag) are reproducible. Defaults to
# "latest" for manual/direct `docker build` runs of this Dockerfile.
ARG CLAUDE_CODE_VERSION=latest
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && \
  apt-get install -y -qq --no-install-recommends \
  ca-certificates \
  curl \
  git \
  jq \
  tmux \
  tzdata \
  unzip \
  && rm -rf /var/lib/apt/lists/*

# /workspace is created (and owned by the non-root user) before the bind
# mount from claude-code-docker.sh replaces its contents at container start.
# Home dir made world-traversable (o+rx): claude-code-docker.sh runs the
# container as the host's uid, which owns none of this image's users, so
# without it that uid couldn't even reach the state paths bind-mounted
# inside ~/claude/ (useradd's default 750 blocks non-owner/non-group
# traversal entirely, regardless of the mounted content's own ownership).
RUN useradd --create-home --shell /bin/bash "${CLAUDE_USER}" \
  && chmod o+rx "/home/${CLAUDE_USER}" \
  && mkdir -p /workspace \
  && chown "${CLAUDE_USER}:${CLAUDE_USER}" /workspace

USER ${CLAUDE_USER}
# Set explicitly (not just implied by useradd) so it still resolves
# correctly when claude-code-docker.sh runs the container as an arbitrary
# --user override (see below) with no matching /etc/passwd entry.
ENV HOME=/home/${CLAUDE_USER}
ENV PATH="${HOME}/.local/bin:${PATH}"
WORKDIR ${HOME}

# Claude Code CLI — native installer, not npm. Pinned to CLAUDE_CODE_VERSION
# (see ARG above) rather than letting the installer silently grab whatever
# is latest, so this build is reproducible.
RUN curl -fsSL https://claude.ai/install.sh | bash -s "${CLAUDE_CODE_VERSION}"

# rtk (token savings) — install, then register its Claude Code hook.
# --auto-patch is required here: `rtk init -g` alone prompts interactively
# to patch settings.json and silently defaults to "no" with no TTY (as
# during this very `docker build`), so without it the hook is never
# actually registered.
RUN curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh \
  && rtk init -g --auto-patch

# Default to Claude Code's fullscreen (alternate-screen) TUI rather than the
# inline default, matching the user's own native settings — otherwise
# interactive use hits the "switch to fullscreen?" prompt every time on a
# fresh container until manually accepted.
RUN jq '. + {"tui": "fullscreen"}' "${HOME}/.claude/settings.json" >/tmp/settings.json \
  && mv /tmp/settings.json "${HOME}/.claude/settings.json"

# Snapshot the resulting ~/.claude/ (rtk's hook registration, etc.) so the
# entrypoint can re-seed it into a persisted (initially empty) host mount at
# that same path — otherwise that mount would shadow it away permanently.
# Made world-readable (a+rX): it's a static local template, not sensitive,
# and the entrypoint reads it as whatever arbitrary uid the host runs the
# container as (see claude-code-docker.sh), not necessarily this image's
# own claude user — some of the original files (settings.json, RTK.md)
# came out of `rtk init` owner-only, which a different uid can't read.
USER root
RUN mkdir -p /opt/claude-defaults \
  && cp -a "${HOME}/.claude/." /opt/claude-defaults/ \
  && chown -R "${CLAUDE_USER}:${CLAUDE_USER}" /opt/claude-defaults \
  && chmod -R a+rX /opt/claude-defaults
COPY entrypoint.sh /usr/local/bin/claude-entrypoint.sh
RUN chmod +x /usr/local/bin/claude-entrypoint.sh
USER ${CLAUDE_USER}

WORKDIR /workspace

# --permission-mode acceptEdits auto-approves file edits/writes and basic
# filesystem commands (mkdir, rm, mv, cp, sed, ...) without prompting, since
# only explicitly bind-mounted folders are reachable here anyway; Bash
# beyond those file operations, WebFetch, and other tool categories still
# prompt normally, unlike --dangerously-skip-permissions (considered and
# rejected: it bypasses those checks too, and its own docs recommend it only
# for sandboxes with no internet access — this container has normal internet
# access, by earlier explicit choice). claude-code-docker.sh overrides this
# default with the same flag plus --add-dir for every mounted folder beyond
# /workspace, since Claude Code scopes file-tool access to declared
# directories regardless of what the container itself can reach.
ENTRYPOINT ["/usr/local/bin/claude-entrypoint.sh"]
CMD ["claude", "--permission-mode", "acceptEdits"]
