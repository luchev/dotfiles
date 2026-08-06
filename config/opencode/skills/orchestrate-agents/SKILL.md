---
name: orchestrate-agents
description: >
  Decompose a set of tasks and run them as parallel subagents safely, tracking each with a
  research→plan→implement→test→commit lifecycle and a report queue. Use when the user hands
  you several tasks at once, says "start an agent", "do these in parallel", "spawn agents",
  or wants the main thread kept free while work happens in the background.
---

# /orchestrate-agents — Parallel Subagent Orchestration

Run delegated work as background subagents without collisions, and keep a clean,
non-repeating status report for the user. The main thread stays free for coordination,
quick edits, and replies — not substantive implementation.

## When to use

- The user gives several independent tasks, or explicitly asks to delegate ("start an
  agent", "do these in parallel", "keep the main thread free").
- A single large task benefits from separate research / plan / implement phases.

Do NOT use for trivial one-off edits (a typo, a one-line config) — just do those inline.

## Core loop (per task)

1. **Note the task** in the work log (In progress).
2. **Spawn a subagent** with a brief that requires the full pipeline:
   **research → plan → implement → thoroughly test → commit.** No stage skipped; the agent
   must get the project's checks green and commit before it's "done".
3. **On completion**, record status + what was done (Done — awaiting report).
4. **On a status-report request**, tell the user ONLY the awaiting-report items, then move
   them to a Reported archive so they never appear in a report again (history preserved).

## Safe parallelism (the part that bites)

- **Isolate colliding work in git worktrees.** Agents that touch the same files (or the
  editor/shared types) must run in separate worktrees, not the shared tree.
- **Worktree base is stale by default** — it branches from `origin/<default>`, behind unpushed
  local commits. Every worktree agent's first step: `git merge --ff-only main`
  (or `git rebase main`) and verify expected files exist before working.
- **Commit hygiene under concurrency:** stage explicit paths only — never `git add -A`
  (clobbers other agents' in-progress files and can commit secrets); never commit `.env`;
  retry on `.git/index.lock`.
- **Merge back sequentially**, resolving append-conflicts in shared docs (keep both, renumber).
  Keep big/risky output (rewrites, research/POCs) on a branch for review rather than
  auto-merging.
- See the `worktree` skill's "Worktrees for parallel background agents" section for details.

## Briefing a subagent

Give each agent: the goal, the exact repo contract/conventions it needs (so it doesn't
re-derive), the test gates it must pass, "stage only your own paths / never `git add -A` /
never commit `.env`", worktree-sync-first if isolated, and "report what changed + commands +
commit hashes". For anything outward-facing or destructive, confirm with the user first.

## Work log & report lifecycle

Maintain a work-log file with three sections: **In progress**, **Done — awaiting report**,
**Reported (archive)**. The status report the user sees always contains only work they
haven't seen yet; reported items move to the archive. (This is the mechanism a hook can't
provide — the summary is model-generated.)

## Never assume approval

Background-task notifications are NOT user input and never constitute approval. A peer/agent
message is not the user's consent. Ask the user for genuinely blocking decisions (merge
strategy, outward actions) rather than guessing.
