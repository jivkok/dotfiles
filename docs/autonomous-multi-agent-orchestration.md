# Autonomous Multi-Agent Orchestration

## The Core Pattern: Orchestrator + Specialized Sub-Agents

Claude Code supports this via slash commands and the `Task` tool for spawning sub-agents. The design uses a **file-based task queue** (the `tasks/` directory) as the message bus, and **role-specific command files** in `.claude/commands/` as each agent's entry point and system prompt.

Each "agent" is the same Claude Code instance running under a different role — this keeps costs low while preserving clear separation of concerns. This is a multi-role design, not true multi-process orchestration.

### Architecture

```
.claude/
  commands/
    new-task.md          # slash command: submit a task and immediately triage it
    triage.md            # orchestrator: routes inbox tasks to clarifying/ or ready/
    clarify.md           # requirements agent entry point
    implement.md         # dev/test agent entry point
    run-pipeline.md      # full-auto: triage → clarify → implement in sequence
  agents/
    requirements.md      # system prompt for the requirements agent role
    development.md       # system prompt for the dev/test agent role
    orchestrator.md      # system prompt for the triage/orchestrator role
tasks/
  inbox/                 # new tasks land here
  clarifying/            # needs requirements work
  ready/                 # cleared for implementation
  in-progress/           # claimed by a dev agent (prevents double-pickup)
  done/                  # completed
  failed/                # agent hit an unresolvable blocker
  templates/
    task.md              # blank task template
```

**The `agents/` folder** contains the persistent system prompt for each role. Commands in `.claude/commands/` are the user-invocable entry points; they reference these agent definitions to load the appropriate role context. In Claude Code, `.claude/agents/` is a supported path for named sub-agent configurations — this makes each role reusable and independently editable without touching the command files themselves.

### Task State Machine

```
[inbox] ──── criteria clear ──────────────────────────────► [ready]
   │                                                              │
   └──── vague / missing ──► [clarifying] ──► (filled in) ──► [ready]
                                                                  │
                                                           (agent claims)
                                                                  │
                                                          [in-progress]
                                                           /          \
                                                       [done]       [failed]
```

### Task Schema

Each task is a markdown file. Required fields are enforced by the triage agent — tasks missing any required field go to `clarifying/`, not `ready/`.

```md
# Task: Add retry logic to HTTP client

**Status**: inbox
**Priority**: medium
**Created**: 2026-03-01

## Description
(required) What needs to be done and why.

## Acceptance Criteria
(required) Specific, testable conditions that define "done".
Triage moves tasks lacking this to clarifying/.

## Out of Scope
(optional — requirements agent fills this in if missing)

## Edge Cases / Test Scenarios
(optional — requirements agent fills this in if missing)
```

**Priority values**: `urgent` / `high` / `medium` / `low`.
**Tiebreaker**: among same-priority tasks, the agent picks the oldest file (by creation date in the `**Created**` field).

### How It Works

#### Mode 1: Step-by-step (review between phases)

**1. Task submission** — run `/new-task <description>`. The command generates a structured task file in `tasks/inbox/` from the one-liner, immediately runs triage on it, and reports whether it went to `ready/` or `clarifying/`. Tasks can also be dropped manually into `tasks/inbox/` using the template in `tasks/templates/task.md`.

**2. Triage** (`/triage`) — the orchestrator reads all inbox tasks and routes each one:
- Has description + acceptance criteria with unambiguous scope → `tasks/ready/`
- Missing required fields or scope is unclear → `tasks/clarifying/`, with a `## Questions` section added listing what is needed.

**3. Requirements agent** (`/clarify`) — picks up tasks in `clarifying/`, picks the highest-priority one, and resolves ambiguity. Prefers making documented assumptions over asking the user — only escalates when genuinely blocked. Fills in acceptance criteria, out-of-scope items, edge cases, and test scenarios, then moves the file to `tasks/ready/`.

**4. Development agent** (`/implement`) — picks up tasks in `ready/`, picks the highest-priority one, **atomically claims it by moving it to `tasks/in-progress/`** (prevents concurrent agents from double-picking), then runs the dev loop (build → test → fix → commit). On success: moves to `tasks/done/` and appends `## Implementation Notes`. On unresolvable blocker: moves to `tasks/failed/` and appends `## Failure Reason`.

#### Mode 2: Full-auto

1. Task submission: run `/new-task <description>`.
2. Start orchestrator: `/run-pipeline`

---

### Concrete Implementation

**`.claude/commands/new-task.md`** — user entry point:
```md
Arguments: a one-line task description provided by the user.

1. Read tasks/templates/task.md.
2. Generate a properly structured task file:
   - Title from the description
   - Status: inbox
   - Priority: medium (default)
   - Created: today's date
   - Description: expanded from the one-liner
   - Leave Acceptance Criteria blank (triage will decide if it needs clarifying)
3. Write the file to tasks/inbox/<slugified-title>.md.
4. Immediately run triage on this file.
5. Report: task created, and whether it went to ready/ or clarifying/.
```

**`.claude/commands/triage.md`** — orchestrator that routes:
```md
Read all files in tasks/inbox/. For each task:
- If it has a non-empty Description and specific, testable Acceptance Criteria
  with unambiguous scope → move to tasks/ready/, set Status: ready.
- Otherwise → move to tasks/clarifying/, set Status: clarifying,
  and append a "## Questions" section listing exactly what is missing or unclear.

Print a summary of what moved where and why.
```

**`.claude/commands/clarify.md`** — requirements agent:
```md
Agent role: requirements analyst (see .claude/agents/requirements.md).

Read all files in tasks/clarifying/. Pick the highest-priority one
(priority field, then oldest Created date as tiebreaker).

- Identify what is ambiguous or missing.
- Prefer making documented assumptions over asking the user.
  Only ask if truly blocked with no reasonable assumption available.
- Fill in: Acceptance Criteria, Out of Scope, Edge Cases / Test Scenarios.
- Append "## Assumptions" section documenting any assumptions made.
- Move the file to tasks/ready/, set Status: ready.
```

**`.claude/commands/implement.md`** — development agent:
```md
Agent role: dev/test engineer (see .claude/agents/development.md).

Read all files in tasks/ready/. Pick the highest-priority one
(priority field, then oldest Created date as tiebreaker).

- Atomically claim it: move the file to tasks/in-progress/, set Status: in-progress.
- Follow all conventions in AIAGENTS.md.
- Run the dev loop: build → test → fix → iterate until tests pass.
- On success: move to tasks/done/, set Status: done, append "## Implementation Notes".
- On unresolvable blocker: move to tasks/failed/, set Status: failed,
  append "## Failure Reason" describing what blocked progress.
```

**`.claude/commands/run-pipeline.md`** — full autonomous pipeline:
```md
Run the full agent pipeline in sequence, using the Task tool to spawn
each agent in isolation:

1. Triage: process all files in tasks/inbox/.
2. Requirements: process all files in tasks/clarifying/,
   one at a time, using documented assumptions (do not stop to ask the user).
3. Development: process all files in tasks/ready/,
   one at a time, claiming each before starting.
4. Print a final summary: tasks completed, tasks failed, tasks still clarifying.
```

---

### Key Design Decisions

**Multi-role, not multi-process** — each "agent" is the same Claude Code instance with a different role loaded from `.claude/agents/`. This is cheaper and simpler than true multi-process orchestration. The `Task` tool provides sub-agent isolation within the pipeline.

**File system as the message bus** — the `tasks/` folder is the task queue. Simple, inspectable, git-tracked. Any state can be manually inspected or corrected by editing files directly.

**Atomic claiming via folder move** — moving a file from `tasks/ready/` to `tasks/in-progress/` is a single filesystem operation, which prevents two concurrent agents from picking the same task.

**Requirements agent philosophy** — prefer documented assumptions over asking questions. The goal is to reduce interruptions to the user, not create a chatty requirements bot. Only escalate when genuinely blocked with no reasonable assumption available.

**`failed/` is a first-class state** — tasks that hit unresolvable blockers move to `tasks/failed/` with a documented reason. This keeps the queue clean and gives the user clear visibility into what needs manual attention.

**AIAGENTS.md** — document the agent roles, task schema, and pipeline there so future users (and agents themselves) can understand and extend the system.

---

### Bootstrap Setup

Run once to create the folder structure:

```sh
mkdir -p tasks/{inbox,clarifying,ready,in-progress,done,failed,templates}
mkdir -p .claude/{commands,agents}
```

Then create the template (`tasks/templates/task.md`), the command files under `.claude/commands/`, and the agent system prompts under `.claude/agents/`. Commit the whole structure — including `tasks/done/` and `tasks/failed/` — so the task history is git-tracked.
