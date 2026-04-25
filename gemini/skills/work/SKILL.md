---
name: work
description: Start or continue feature work on a task or GitHub issue. Sets up a worktree, fetches task context, then drives research → plan → implement phases with context compaction between phases to keep context clean.
---

# /work — Feature Work Orchestrator

Research → Plan → Implement, with compaction between phases. State persisted to `$WT_DIR/.claude/`.

## Argument Parsing

- `my-feature` — start from research (or resume at last completed phase)
- `123` — use GitHub issue #123 as the task
- `my-feature plan` — jump to planning
- `my-feature implement` — jump to implementation
- `my-feature lint` — jump directly to lint check (I3L)
- `my-feature commit` — jump directly to commit (I4)
- `my-feature publish` — jump directly to publish (I5)
- `my-feature monitor` — jump directly to CI monitoring (I6)

`TASK` = first arg (issue number or plain name). `PHASE` = second word (default: `research`).
`UPSTREAM_BRANCH` = set if user says this work is stacked on / follows another branch.

## State Directory

```bash
STATE_DIR=$WT_DIR/.claude
mkdir -p $STATE_DIR
```

When resuming at `plan`/`implement`, look for `$STATE_DIR/RESEARCH.md` / `PLAN.md`. If missing, tell user to re-run from the previous phase.

After implement completes: `rm -rf $STATE_DIR`.

## Step 0: Fetch Task

If `TASK` is a number:
```bash
gh issue view $TASK --json title,body,labels,assignees
```

Otherwise use the task name as the description. Print one-line summary.

## Step 1: Clarifying Questions

Ask if: stacking is unclear (implied deps but no `UPSTREAM_BRANCH`), description is vague, or scope is ambiguous. Skip if nothing is unclear.

## Step 2: Create Worktree

Invoke `/wt-new $TASK` (with `UPSTREAM_BRANCH` if set). If worktree already exists, note path and continue.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
WT_DIR="$REPO_ROOT/.worktrees/$TASK"
```

**Switch to the worktree. All subsequent commands run from here.**

## Step 3: Write Ticket Context

Write `$STATE_DIR/TICKET.md`:
```markdown
# <TASK>: <Summary>

**Stacked on:** <UPSTREAM_BRANCH>   ← omit if not stacked

## Description
<description>
```

Skip if file already exists.

---

## Phase: RESEARCH

*Skip if `$PHASE` is `plan` or `implement`.*

Invoke `/research $TASK`. It will explore the codebase in parallel, write RESEARCH.md, and pause.

**Stop here when /research stops.**

---

## Phase: PLAN

*Skip if `$PHASE` is `implement`.*

Invoke `/plan $TASK`. It will read TICKET.md + RESEARCH.md, spawn a plan agent, write PLAN.md, and pause.

**Stop here when /plan stops.**

---

## Phase: IMPLEMENT

*Skip based on `$PHASE`:*
- *`lint` — skip I1–I3, run I3L only, then pause*
- *`commit` — skip I1–I3L, run I4–I7*
- *`publish` — skip I1–I4, run I5–I7*
- *`monitor` — skip I1–I5, run I6–I7*

### I1: Load context

Read `$STATE_DIR/TICKET.md`, `RESEARCH.md`, `PLAN.md`. If PLAN.md missing, stop.

Create tasks from plan sections (one per major change).

### I2: Implement

For each task:
1. Mark task in-progress
2. Read files before editing
3. Implement per plan
4. `go build ./...` to verify compilation
5. Mark task completed

### I3: Tests

```bash
go test ./...
```

Fix failures before proceeding.

### I3L: Lint

Invoke `/lint-go check` on every file changed in this branch:

```bash
git diff --name-only main...HEAD | grep '\.go$'
```

Pass the resulting file list to `/lint-go check <files>`. Fix all violations before proceeding. Re-run build and tests after fixing if any files were modified.

*If `$PHASE` is `lint`: stop here after fixing and print:*
```
## Lint Complete

Run /compact then:
  /work <TASK> commit
```

### I4: Commit

Stage specific files (never `git add -A`), then invoke `/commit-msg`.

### I5: Publish

Invoke `/publish $TASK`. This rebases, updates the commit message, runs tests, and creates/updates the GitHub PR.

### I6: Monitor CI

After publishing, get the PR number:

```bash
gh pr view --json number --jq '.number'
```

Then invoke the loop skill to poll every 5 minutes:

```
/loop 5m /investigate-ci <PR_NUMBER>
```

The loop will call `/investigate-ci` on each tick. It should:
- Report any newly failed jobs with their classification and fix
- Print "CI still running — N jobs in progress" when no failures
- **Stop the loop** when:
  - All checks pass
  - A code-fix failure is found — report it and stop so the user can act
  - The build is cancelled or timed out

Only infrastructure failures should be noted and the loop continued.

### I7: Cleanup

```bash
rm -rf "$STATE_DIR"
```

Print: `## Done — run /summarize for a session overview.`

---

## Key Rules

- **Refactor-first workflow:** Never mix refactoring and new feature work in the same PR. Always split into two PRs:
  1. **PR 1 — Refactor only:** rename, restructure, move code, no behavior change. Get it merged first.
  2. **PR 2 — Feature only:** implement new behavior on the clean post-refactor base.
- Never modify files outside the worktree during research/plan phases
- Never skip phase pauses — compaction is intentional
- Always read files before editing
- Use parallel agents for independent exploration
- If a plan step turns out wrong: update PLAN.md, note deviation before proceeding
