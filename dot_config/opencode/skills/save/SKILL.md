---
name: save
description: >
  Save the current session context to a file so it can be restored in a future
  conversation. Writes a snapshot of task, progress, key decisions, and open
  items to ~/.config/opencode/sessions/<name>.md. Use when you want to pause
  and resume later.
allowedTools:
  - Bash(bash ~/.config/opencode/zellij-status.sh status *)
  - Bash(date *)
  - Bash(git branch --show-current)
  - Bash(git log --oneline -5)
  - Bash(ls ~/.config/opencode/sessions/)
  - Bash(mkdir -p ~/.config/opencode/sessions)
  - Read
  - Write
  - Todowrite
  - Todoread
---

# /save — Save Session Context

Capture everything needed to resume this session cold in a future conversation.

## Argument Parsing

- (empty) — use current branch name or "session-<date>" as the file name
- `<name>` — use this as the session file name (no spaces; dashes OK)

## Step 1: Determine session name

```bash
bash ~/.config/opencode/zellij-status.sh status "saving session"
```

If a name argument was given, use it. Otherwise, distill the session's task into
3–5 keywords capturing *what* the work was, formatted as lowercase kebab-case,
e.g. `fix-auth-middleware`, `add-csv-export`, `debug-metric-spike`.

Avoid generic words like `session`, `work`, `task`, `update`.

If nothing is known yet, fall back to `session-<YYYY-MM-DD>` using today's date.

## Step 2: Collect context

Gather from conversation history only — no extra shell calls beyond what's listed above:

- **Task**: one-line description of what we were working on
- **Branch**: current git branch
- **Recent commits**: last 5 commits (run `git log --oneline -5`)
- **Progress**: what was completed and what is still outstanding
- **Open items**: the next concrete action(s) needed to continue
- **Key decisions**: non-obvious choices made (why, not what)
- **Notes**: any other context needed to pick this up cold (file paths, commands, caveats)

Also read active todos (via `Todoread`) to capture task state.

## Step 3: Write the session file

```bash
mkdir -p ~/.config/opencode/sessions
```

Write to `~/.config/opencode/sessions/<name>.md`:

```markdown
# Session: <name>
Saved: <YYYY-MM-DD HH:MM>

## Task
<one-line description>

## Branch
<branch name>

## Recent Commits
<git log --oneline -5 output>

## Progress
- [x] <completed item>
- [ ] <outstanding item>

## Open Items (start here)
1. <first concrete action to take>
2. <second action if applicable>

## Key Decisions
- <decision>: <why it was made>

## Notes
<any other cold-start context — file paths, commands, caveats>
```

Rules:
- **Open Items** is the most important section — make it actionable enough that the next session can start without reading anything else.
- Omit empty sections if nothing to put there.
- Keep the whole file under ~60 lines.

## Step 4: Confirm

```bash
bash ~/.config/opencode/zellij-status.sh status ""
```

Print:

```
Session saved → ~/.config/opencode/sessions/<name>.md

To restore in a new conversation:
  /restore <name>
```
