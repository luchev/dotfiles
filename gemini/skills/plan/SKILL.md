---
name: plan
description: Plan implementation for a task by reading research and producing PLAN.md. Use after /research completes.
---

# /plan — Implementation Planning for a Task

Reads TICKET.md + RESEARCH.md, spawns a plan agent, writes PLAN.md.

## Argument Parsing

`TASK` = task name or GitHub issue number. Required.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
WT_DIR="$REPO_ROOT/.worktrees/$TASK"
STATE_DIR="$WT_DIR/.claude"
```

---

## P1: Load context

Read `$STATE_DIR/TICKET.md` and `$STATE_DIR/RESEARCH.md`. If either is missing, stop:
```
RESEARCH.md not found. Run /research <TASK> first.
```

## P2: Spawn plan agent

Spawn a planning agent with the full task description and research findings. Instruct it to produce:
- Step-by-step changes with exact file paths and function signatures
- Test strategy (what to test, how)
- Rollout / risk considerations
- What is explicitly out of scope

## P3: Write PLAN.md

Save the agent's output to `$STATE_DIR/PLAN.md`:

```markdown
# Plan: <TASK>

## Summary
<one paragraph: what this changes and why>

## Changes
| File / Component | What | Why / How |
|---|---|---|
| ... | ... | ... |

## Test Strategy
<what tests to write or update>

## Rollout / Risk
<any risk, feature flags, staged rollout needed>

## Out of Scope
<what we are explicitly not doing>
```

## P4: Pause

```
## Plan Complete

Plan: $WT_DIR/.claude/PLAN.md

Edit PLAN.md directly if you want changes.
Run /compact then:
  /work <TASK> implement
```

**Stop here.**
