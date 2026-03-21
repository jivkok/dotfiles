Create a new task and immediately triage it.

## Input

Arguments: $ARGUMENTS

Parse the arguments as follows:
- If the first word is a priority tag — `[urgent]`, `[high]`, `[medium]`, or `[low]` — extract it as the priority (without brackets). The remainder is the description.
- Otherwise, priority is `medium` and the entire argument string is the description.

If no arguments are provided, tell the user: "Usage: /create-task [priority?] <description>" and stop.

## Step 1: Generate the task file

Slug the description into a filename:
- Lowercase
- Replace spaces with hyphens
- Strip punctuation except hyphens
- Truncate to 50 characters
- Append `.md`

Example: "Add retry logic to the HTTP client" → `add-retry-logic-to-the-http-client.md`

Read `tasks/templates/task.md`. Fill in the following fields:
- Title: the description (title-cased)
- Status: `inbox`
- Priority: extracted priority
- Created: today's date (YYYY-MM-DD)
- Description: the description as provided — do not expand or interpret it yet

Leave Acceptance Criteria, Out of Scope, Edge Cases, and all agent-populated sections blank.

Write the file to `tasks/inbox/<slug>.md`.

## Step 2: Triage the task inline

Apply the triage rubric from `.claude/agents/orchestrator.md` to this one file only. Do not process any other files in `tasks/inbox/`.

Evaluate:
1. Is the description present and specific enough to convey intent?
2. Are acceptance criteria present, specific, and testable? (At this stage they will almost always be absent — that is fine and expected.)
3. Is the scope unambiguous?

For a freshly submitted one-liner, criteria will typically be missing. Route accordingly — do not invent criteria to force a `ready/` routing.

**If ready:** move file to `tasks/ready/`, set `**Status**: ready`.

**If clarifying:** append a `## Questions` section listing exactly what is missing, move file to `tasks/clarifying/`, set `**Status**: clarifying`.

## Step 3: Report

Print a single concise summary:

```
Task created: tasks/<destination>/<slug>.md
→ Routed to <destination>/ — <reason>.
```

Examples:
```
Task created: tasks/ready/add-dark-mode-toggle.md
→ Routed to ready/ — description and acceptance criteria are specific and testable.

Task created: tasks/clarifying/add-retry-logic.md
→ Routed to clarifying/ — missing: acceptance criteria, scope unclear (which client?).
```

Do not print the full file contents. Do not ask any follow-up questions.
