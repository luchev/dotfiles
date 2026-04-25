---
name: research
description: Research a task or GitHub issue by exploring the codebase and writing RESEARCH.md. Use when starting work on a task or when research needs to be re-run.
---

# /research — Codebase Research for a Task

Reads the task description, explores the codebase in parallel, writes RESEARCH.md.

## Argument Parsing

`TASK` = task name or GitHub issue number (e.g. `my-feature` or `123`). Required.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
WT_DIR="$REPO_ROOT/.worktrees/$TASK"
STATE_DIR="$WT_DIR/.claude"
```

If `$STATE_DIR/TICKET.md` exists, use it. Otherwise:
- If `TASK` is a number: `gh issue view $TASK --json title,body,labels` to fetch issue description
- Otherwise: ask user for a one-paragraph task description

---

## R1: Decompose

Read task description. Identify 2–4 focused exploration questions covering:
- Where is the relevant code? (entry points, key files)
- What interfaces/types/models are involved?
- What existing patterns does this area use?
- What are the integration points with other packages?

## R2: Parallel explore agents

Launch all questions as concurrent exploration tasks (`subagent_type: Explore`, `thoroughness: very thorough`). Each agent prompt must include:
- The specific question
- Likely directories to look in
- Request for file paths, line numbers, and code snippets

Wait for all agents to complete before proceeding.

## R3: Write RESEARCH.md

Synthesize all agent findings. Save to `$STATE_DIR/RESEARCH.md`:

```markdown
# Research: <TASK>

## Key Files
<file paths and what they do>

## Relevant Interfaces / Types
<interfaces, structs, key types>

## Existing Patterns
<patterns in use that the implementation should follow>

## Integration Points
<what this change touches or depends on>

## Open Questions
<anything still unclear>
```

## R4: Pause

```
## Research Complete

Findings: $WT_DIR/.claude/RESEARCH.md

Run /compact then:
  /work <TASK> plan
```

**Stop here.**
