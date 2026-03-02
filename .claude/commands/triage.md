Load the orchestrator role from `.claude/agents/orchestrator.md` and apply it to all files in `tasks/inbox/`.

## Scope

Process every file in `tasks/inbox/`. Do not process files in any other folder.
If `tasks/inbox/` is empty, print "Inbox is empty. Nothing to triage." and stop.

## Output

After processing all files, print a summary:

```
Triage complete. N tasks processed.

→ ready/    filename.md — <one-line reason>
→ ready/    filename.md — <one-line reason>
→ clarifying/ filename.md — <what is missing>
→ clarifying/ filename.md — <what is missing>
```

Keep each line to one sentence. The reason should name the specific gap (e.g., "missing acceptance criteria" or "scope unclear — which platform?"), not restate the routing decision.
