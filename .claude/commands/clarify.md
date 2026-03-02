Load the requirements agent role from `.claude/agents/requirements.md` and apply it to all files in `tasks/clarifying/`.

## Scope

Process every file in `tasks/clarifying/`. If the folder is empty, print "Nothing to clarify. tasks/clarifying/ is empty." and stop.

Process tasks in priority order: `urgent` → `high` → `medium` → `low`. Within the same priority, process oldest `**Created**` date first.

## Output

After processing all tasks, print a summary:

```
Clarify complete. N tasks moved to ready/.

→ ready/  filename.md
   Assumptions: <one-line summary of key assumptions made>

→ ready/  filename.md
   Assumptions: none — criteria were already specific enough to fill in directly
```

If any task required escalating a question to the user, list it separately:

```
Blocked (N):
→ filename.md — <what information is needed to proceed>
```

Keep each entry to two lines. Do not print full file contents.
