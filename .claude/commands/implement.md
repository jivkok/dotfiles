Load the development agent role from `.claude/agents/development.md` and implement one task from `tasks/ready/`.

## Scope

Process one task only. If `tasks/ready/` is empty, print "Nothing to implement. tasks/ready/ is empty." and stop.

Select the highest-priority task (`urgent` → `high` → `medium` → `low`). Within the same priority, pick the oldest `**Created**` date first. If multiple tasks were available, note which was selected and why.

## Output

On success:

```
Implemented: tasks/done/<filename>.md
→ Acceptance criteria: 4/4 met.
→ Tests: 23 passed, 0 failed.
→ Notes: <one-line summary of any non-obvious decisions made>
```

On failure:

```
Failed: tasks/failed/<filename>.md
→ Blocked: <specific description of what prevented completion and what is needed to unblock>
```

Do not print full file contents. Do not ask whether to continue to the next task.
