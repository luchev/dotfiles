---
name: save
description: Save the current session context to a file so it can be restored in a future conversation. Writes a snapshot of task, progress, key decisions, and open items to ~/.claude/sessions/<name>.md. Use when you want to pause and resume later.
allowedTools:
  - Bash(bash ~/.dotfiles/claude/zellij-status.sh status *)
  - Bash(date *)
  - Bash(git branch --show-current)
  - Bash(git log --oneline -5)
  - Bash(ls ~/.claude/sessions/)
  - Bash(mkdir -p ~/.claude/sessions)
  - Read
  - Write
  - TaskList
---

# /session-save — Save Session Context

Capture everything needed to resume this session cold in a future conversation.

## Argument Parsing

- (empty) — use current branch name or "session-<date>" as the file name
- `<name>` — use this as the session file name (no spaces; dashes OK)

## Step 1: Determine session name

```bash
bash ~/.dotfiles/claude/zellij-status.sh status "saving session"
```

If a name argument was given, use it. Otherwise, synthesize a short descriptive slug from the session's task:

- Distill the task into 3–5 keywords that capture *what* the work was (not the branch name or date)
- Format as lowercase kebab-case, e.g. `fix-auth-middleware`, `add-csv-export`, `debug-metric-spike`
- Avoid generic words like `session`, `work`, `task`, `update`
- If truly nothing is known yet, fall back to `session-<YYYY-MM-DD>` using today's date

## Step 2: Collect context

Pull from the conversation history only — no extra shell calls beyond what is listed above.

Gather:
- **Task**: one-line description of what we were working on
- **Issue**: tracker key + URL if the work is associated with an issue/ticket
- **Branch**: current git branch
- **Recent commits**: last 5 commits (run `git log --oneline -5`)
- **Progress**: what was completed and what is still outstanding
- **Open items**: the next concrete action(s) needed to continue
- **Key decisions**: non-obvious choices made (why, not what)
- **PR**: URL and status if one exists
- **Blockers**: anything that was blocking progress
- **Notes**: any other context needed to pick this up cold (file paths, commands, caveats)

Also call `TaskList` to capture any active tasks.

## Step 3: Write the session file

```bash
mkdir -p ~/.claude/sessions
```

Write to `~/.claude/sessions/<name>.md`:

```markdown
# Session: <name>
Saved: <YYYY-MM-DD HH:MM>

## Task
<one-line description>

## Issue
<KEY — URL>
(omit section if no associated issue)

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

## PR
<URL and status, or "None">

## Blockers
<blocker description, or omit section if none>

## Notes
<any other cold-start context — file paths, commands, caveats>

## Tasks
<TaskList output if tasks exist, or omit>
```

Rules:
- **Open Items** is the most important section — make it actionable enough that the next session can start without reading anything else.
- Omit empty sections (Issue, Blockers, Notes) if there is nothing to put there.
- Keep the whole file under ~60 lines.

## Step 4: Confirm

```bash
bash ~/.dotfiles/claude/zellij-status.sh status ""
```

Print:

```
Session saved → ~/.claude/sessions/<name>.md

To restore in a new conversation:
  /session-restore <name>
```
