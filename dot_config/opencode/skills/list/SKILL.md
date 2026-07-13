---
name: list
description: >
  List all saved sessions in ~/.config/opencode/sessions/ with their task and
  save date. Use to see what work has been saved and can be restored.
allowedTools:
  - Bash(ls ~/.config/opencode/sessions/)
  - Bash(grep *)
  - Read
---

# /list — List Saved Sessions

Show all saved sessions with a one-line summary each.

## Step 1: Check for sessions

```bash
ls ~/.config/opencode/sessions/ 2>/dev/null
```

If the directory is empty or does not exist, print:

```
No saved sessions. Use /save to save the current session.
```

And stop.

## Step 2: Read each session file

For each `.md` file found, read it and extract:
- **Saved** date (from the `Saved:` line)
- **Task** (from the `## Task` section)
- **Branch** (from the `## Branch` section)
- **Open items count** (count `[ ]` lines in `## Open Items`)

## Step 3: Print the table

```
## Saved Sessions

  NAME              SAVED         BRANCH                     TASK
  ────────────────────────────────────────────────────────────────────
  my-feature        2026-05-27    feature/rate-limit         Add rate limiting to auth service
  another-task      2026-05-26    fix/nil-mapper             Fix nil pointer in mapper layer

To restore: /restore <name>
To save current session: /save [name]
```

Rules:
- Sort by saved date, newest first.
- Truncate task to 50 chars if longer.
- If there are open items, append ` (N open)` after the task.
