---
name: brainstorm
description: >
  Mandatory structured brainstorming before any creative or implementation work.
  Use before creating features, building components, adding functionality, or modifying behavior.
  Trigger when user says "let's build X", "add feature", "implement X", "create X",
  or starts any new implementation without prior exploration.
---

# Brainstorm Command

**Description**: You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores requirements and design before implementation.

## When to Use

Use this command before:
- Creating new features
- Building new components
- Adding functionality
- Modifying existing behavior
- Any creative development work

## Process

### 1. Explore Context
- Review relevant files, documentation, and recent commits
- Understand the current system architecture
- Identify constraints and dependencies

### 2. Ask Clarifying Questions

**Find the facts yourself.** Anything discoverable from the repo, the git history,
the docs, or the web is your job — dispatch a subagent. Only ask the user for what
lives in their head: intent, priorities, constraints they haven't written down.
Asking them to go look something up is offloading your work.

**Batch by frontier, not one at a time.** Compute the *frontier* — every question
whose answer does not depend on another unresolved question — and ask that whole
set in one numbered round, each with your recommended default so the user can
reply "1, 3, defaults elsewhere". Recompute the frontier from the answers and ask
the next round. Stop when the frontier is empty.

Questions behind an unresolved dependency stay unasked. Asking "which database?"
before "does this need to persist at all?" wastes a round and anchors the answer.

Cover, across rounds:
- Purpose: Why are we building this?
- Constraints: What are the technical/business limitations?
- Success criteria: How will we know it's done right?
- User impact: Who will use this and how?

### 3. Propose Approaches
Present 2-3 different approaches with:
- Trade-offs for each approach
- Pros and cons
- Your recommendation with reasoning
- Resource/complexity estimates

For non-trivial designs, generate these in parallel rather than sequentially: spawn one
subagent per approach, all given the *same* problem statement but a different mandated
stance — e.g. `minimal-change` (smallest diff to existing code), `clean-architecture`
(right structure, ignore migration cost), `pragmatic` (ship this quarter). Forcing distinct
stances produces genuine alternatives; splitting by file or component just produces the
same answer three times.

Read the returned proposals yourself and write the comparison — do not paste subagent
output through to the user.

### 4. Present Design Incrementally
Get approval for each major section:
- Architecture overview
- Data models
- API contracts
- User interface (if applicable)
- Error handling strategy

### 5. Document Design
Save the design to `docs/designs/YYYY-MM-DD-<topic>.md` with:
- Problem statement
- Proposed solution
- Architecture diagrams (if needed)
- Implementation approach
- Testing strategy
- Rollout plan

### 6. Commit Design
Create a commit with the design document before implementation

### 7. Transition
After design is approved, transition to the `/plan` command to create detailed implementation steps

## Key Principles

- **Even simple projects need design** - A todo list, single function, or config change still needs design (though the design may be brief)
- **Get approval incrementally** - Don't write the entire design at once
- **Ask before assuming** - Clarify requirements rather than guessing
- **Document decisions** - Record why choices were made

## Anti-Patterns to Avoid

❌ Skipping brainstorming for "simple" projects
❌ Writing code before design approval
❌ Making assumptions about requirements
❌ Designing everything in isolation without approval
❌ Moving to implementation without documenting decisions
