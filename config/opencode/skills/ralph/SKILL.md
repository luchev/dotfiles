---
name: ralph
description: >
  Drive long tedious autonomous coding jobs with the ralph loop — a bash driver
  that re-feeds a PROMPT file to fresh `opencode run` sessions until the agent
  prints RALPH_COMPLETE. Fresh context each iteration; git commits are the
  loop's memory. Use when the user says "ralph", "grind until done", "run this
  overnight", "keep working until finished", or has a long multi-step job
  (migration, bulk refactor, doc sweep) too big for one session.
---

# ralph — autonomous long-task loop

One dumb `while` loop beats one clever session for long grinds: every iteration
gets fresh context (no rot), reads git history to resume, commits verified
progress, stops only on an exact completion marker.

## When to use

- Multi-hour / many-chunk jobs: migrations, bulk refactors, feature checklists, test sweeps
- Jobs with machine-verifiable done criteria (tests/build/lint)
- NOT for interactive pairing or fuzzy "make it nice" goals

## Step 1 — write PROMPT.md (with the user)

In the project root. The agent re-reads it cold every iteration, so it must be self-contained:

```markdown
# Goal

<one-paragraph outcome statement>

# Context

<files/modules/constraints the agent can't guess>
Build/test commands: <exact commands that prove work>

# DONE checklist (ALL must be true and verified)

- [ ] <criterion 1 — objectively checkable>
- [ ] <criterion 2>
```

Rules: criteria objective, verification commands explicit, scope tight. Vague
checklist = infinite loop.

## Step 2 — launch

```bash
ralph                    # ./PROMPT.md, 25 iterations max, auto-commits
ralph -f plan.md -n 50   # custom file / budget
ralph --no-commit        # dry-run style: don't touch git history
ralph -m <model>         # pin model, else opencode default
```

Monitor: `tail -f .ralph/log-N.txt`. Stop: Ctrl-C (committed progress survives).
Exits: 0 complete · 3 blocked-by-agent · 4 crash streak · 5 iteration budget spent.

## Step 3 — after completion

1. Review together: `git log -p <start>..HEAD` before any push.
2. Run `/learn` to bank what worked into memory/skills — this is what makes the
   next ralph run smarter.

## Safety

Unattended on a real machine. Prompt must not request destructive operations;
tests/builds are the verify gate; never push unreviewed checkpoints.
