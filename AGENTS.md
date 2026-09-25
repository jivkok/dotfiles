# Dotfiles (macOS / Linux / Windows) — AI Agents Entry Point

## Purpose

This repository bootstraps macOS, Linux, and Windows machines by installing core CLI/dev tools (Homebrew / apt / pacman / Chocolatey), configuring shell environments (bash/zsh), git, vim/neovim, tmux, fzf, and linking dotfiles in a way that preserves local overrides. Changes involve editing setup/configure scripts; validate with `/run-tests` (and the full suite, `/run-tests --full`) before reporting done.

## Agent Validation Steps

After any code change:
1. While iterating, run `/run-tests` (runs `tests/run-tests.sh --changed`: only the tests covering the changed files).
2. Before reporting done, run the full suite: `/run-tests --full` (no `--changed`) — mandatory.
3. If setup files changed (see `docs/testing.md` — Setup Files Per OS), run `/setup-test-envs` first.
4. New scripts need a covering test (`# COVERS:` header) or a `tests/coverage-exclude` entry with a reason — `test-coverage-map.sh` enforces this.
5. Scripts must be idempotent — safe to run multiple times on an already-configured system.

## Docs for when working in the repo (read next)

- `docs/structure.md` — repo layout, flows, invariants
- `docs/os-matrix.md` — cross-platform differences and mappings
- `docs/development.md` — conventions, rules, refactoring playbook, and validation checklists
- `docs/testing.md` — testing approach, workflow, environments, and scripts reference
- `docs/coding-conventions.md` — coding conventions (detail files in `docs/coding-conventions/`)
- `docs/mcp-servers.md` — MCP servers configured for AI agents

## Task Pipeline

This repo uses a file-based multi-agent task pipeline for managing work autonomously. Submit tasks with `/create-task <description>`. Tasks flow through:

```
tasks/inbox/ → tasks/clarifying/ → tasks/ready/ → tasks/in-progress/ → tasks/done/
```

Commands:
- `/create-task <description>` — submit a task and immediately triage it
- `/triage` — route all inbox tasks to ready/ or clarifying/
- `/clarify` — fill in requirements for all clarifying tasks
- `/implement` — implement one ready task (includes /simplify review)
- `/run-pipeline` — full-auto: triage → clarify → implement until empty

ONLY if you are working on the pipeline itself (commands, agents, task schema), read `docs/autonomous-multi-agent-orchestration.md`.
