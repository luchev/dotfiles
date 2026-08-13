---
name: delegate
description: Execute an implementation plan by dispatching one fresh subagent per task, reviewing each task before moving on, and tracking progress in a ledger that survives compaction. Use for plans whose tasks are mostly independent and long enough that running them inline would blow the context. Trigger when the user says "delegate this plan", "run this with subagents", "execute in parallel agents", or when /execute would exhaust the context. Use /execute instead for short plans or tightly coupled tasks.
---

# /delegate — Subagent-Driven Plan Execution

One fresh subagent per task, a review gate after each, a whole-branch review at
the end. You coordinate; you do not implement.

**Why:** a subagent you brief precisely stays focused, and its context never
pollutes yours. Yours stays clean for coordination — which is the only thing
that cannot be delegated.

## When Not to Use

- Plan has fewer than ~4 tasks → `/execute`
- Tasks are tightly coupled (each needs the last one's discoveries) → `/execute`
- No written plan → `/plan` first

## Setup

1. Work in a worktree. `/wt-new` if there isn't one. Never start on `main`.
2. Read the plan **once**. Note its global constraints. Create one todo per task.
3. Create the ledger.
4. Pre-flight scan: read the plan for tasks that contradict each other or its
   own constraints, and for anything it mandates that a reviewer would call a
   defect. Present all of it as **one** batched question before Task 1 — not one
   interrupt per discovery mid-run. Clean scan → proceed without comment.

### The ledger

Your conversation does not survive compaction. The single most expensive
failure in this workflow is a coordinator that lost its place and re-dispatched
tasks that were already done.

Ledger lives at `.delegate/<plan-basename>/progress.md`. Keep it out of the
repo's history without touching its `.gitignore`:

```bash
grep -qxF '.delegate/' .git/info/exclude || echo '.delegate/' >> .git/info/exclude
```

First line names the plan:

```
# delegate ledger — plan: docs/plans/foo.md
```

On start, if a ledger exists and its first line names *your* plan: every task
with a `Task N: complete` line is done — resume at the first without one. A
ledger naming a different plan is not yours; leave it and start your own.

After compaction, trust the ledger and `git log` over your own recollection.

## Model Selection

Always name the model explicitly when dispatching. Omitting it inherits your
session's model — usually the most expensive one — which defeats this section.

| Work | Model |
|---|---|
| Plan text contains the code to write (transcription + tests) | cheapest |
| Single-file mechanical fix | cheapest |
| 1-2 files, complete spec | cheap |
| Multi-file, integration concerns | standard |
| Design judgment, broad codebase understanding | most capable |
| Final whole-branch review | most capable |
| Fix rounds 4-5 | one tier above whatever got stuck |

Turn count beats token price: the cheapest model often takes 2-3× the turns on
multi-step work and costs more overall. Mid-tier is the floor for reviewers and
for implementers working from prose rather than from code in the plan.

## The Task Loop

Everything you paste into a dispatch, and everything a subagent prints back,
stays in your context for the rest of the session and is re-read every turn.
**Hand artifacts over as files.**

### 1. Dispatch

Record `BASE=$(git rev-parse HEAD)` before dispatching — the review needs it.

Extract the task's text to `.delegate/<plan>/task-N-brief.md`. The dispatch
prompt contains, and contains only:

1. One line on where this task fits
2. The brief path — "read this first, it is your requirements, use its values verbatim"
3. Interfaces and decisions from earlier tasks that the brief cannot know
4. Your resolution of any ambiguity you spotted in the brief
5. The report-file path (`task-N-report.md`) and what to put in it

Exact values — numbers, strings, signatures, test cases — live in the brief
only. Never make a subagent read the whole plan.

Do not paste prior-task summaries into later dispatches. A fresh subagent needs
its task, the interfaces it touches, and the global constraints. Nothing else.

Never dispatch two implementers in parallel — they conflict.

Record the agent's identity; rounds 1-3 resume it.

After a free-tier model retry, background task IDs (`bg_...`) can 404. Collect
agent output with the continuation session (`task(task_id="ses_...")`) or
`session_read` instead — never re-dispatch fresh to re-ask a question the
session already answered.

### 2. Handle the report

The implementer writes its full report to the report file and returns only:
status, commits, a one-line test summary, concerns.

| Status | Action |
|---|---|
| `DONE` | Generate the review package, dispatch the reviewer |
| `DONE_WITH_CONCERNS` | Read them. Correctness or scope → address before review. Observations → note and proceed |
| `NEEDS_CONTEXT` | Supply what's missing, re-dispatch |
| `BLOCKED` | Diagnose: context problem → more context, same model. Needs reasoning → more capable model. Too large → split. Plan is wrong → escalate to the user |

Never re-dispatch the same model on the same prompt after a `BLOCKED`.
Something has to change.

### 3. Review the task

```bash
git log --oneline $BASE..HEAD  > .delegate/<plan>/review-N.md
git diff --stat $BASE..HEAD   >> .delegate/<plan>/review-N.md
git diff -U10  $BASE..HEAD    >> .delegate/<plan>/review-N.md
```

`$BASE` is the commit you recorded — **never `HEAD~1`**, which silently drops
every commit but the last of a multi-commit task.

The reviewer gets three paths (brief, report, review package) plus the global
constraints copied verbatim from the plan. The diff never enters your context.

Both verdicts are required: **spec compliance** and **code quality**. The
implementer's self-review does not substitute for either.

Do not:
- ask the reviewer to re-run tests the implementer already ran on the same code
- add open-ended directives ("check all uses") without a concrete reason
- pre-judge. If your prompt contains "don't flag X" or "at most minor", stop —
  you are sparing yourself a review loop. Let it raise the finding and
  adjudicate it properly.

A reviewer may report "cannot verify from diff" for requirements living in
unchanged code. Those do not block the review, but you resolve each one — you
hold the cross-task context it lacks. A confirmed gap is a failed spec review.

### 4. The fix loop

Triggers on: spec ❌, any Critical/Important finding, or a "cannot verify" item
you confirmed.

Two things leave immediately:

- **Minor findings** never enter the loop. Log them:
  `Task N: minor (deferred): <one-liner>` and point the final review at them.
- **Plan-mandated findings** are the user's call. Present the finding beside
  the plan text and ask which governs. Do not dismiss it, and do not dispatch a
  fix that contradicts the plan.

Everything else loops. One round = one fix dispatch + one scoped re-review.
**Five rounds maximum.**

- **Rounds 1-3** — resume the original implementer with the findings verbatim.
  Its context is intact.
- **Rounds 4-5** — fresh implementer, one tier up: *"A prior implementer
  attempted this N times; you own it now. Read the report file for what was
  tried."* Three failed resumes means it cannot see its own problem.

Every round: the implementer fixes, re-runs the tests covering the amended code,
appends to the same report file. Before re-dispatching the reviewer, confirm the
fix report has the covering tests, the command, and the output.

The re-review is **scoped** — diff from the head the last review saw. It
verdicts each finding ADDRESSED / NOT ADDRESSED and flags new breakage in the
fix diff only. New Critical/Important breakage joins the open list;
out-of-scope observations become deferred minors.

Ledger each round:
`Task N: fix round R/5 (X addressed, Y open — <one-liners>; commits a7..b7)`

**Never fix findings yourself.** Coordinator fixes pollute your context and skip
review.

**The breaker.** Round 5 still open → stop dispatching and adjudicate each
finding yourself:

- Reviewer wrong or contestable → park: `Task N: parked — <finding> — ruling: <why the code stands>`
- Real but nothing depends on it → park with a ruling saying so
- Real and load-bearing (a later task builds on it, or it exposes a plan
  defect) → **STOP.** `Task N: BLOCKED — <reason>` and report to the user with
  the finding, the colliding plan text, and the fix history.

Adjudicate only at the cap. Adjudicating early to end a loop is pre-judging
under another name. Every adjudication is a ledger line; silent discards are
forbidden.

### 5. Complete

`Task N: complete (commits base7..head7, review clean)` — or `(..., K parked)`
after a tripped breaker. Mark the todo, move on.

Never start the next task with open Critical/Important findings that are
neither fixed nor parked-with-ruling at the cap.

## Final Review

Package the whole branch (`git merge-base main HEAD` → `HEAD`), dispatch
`/review` on the most capable model, and point it at the ledger's deferred and
parked lines so it can triage what must be fixed before merge.

Findings → **ONE** fix dispatch with the complete list, not one fixer per
finding. Per-finding fixers each rebuild context and re-run suites; that wave
can cost more than every task combined. Then exactly one scoped re-review.
Residuals are adjudicated as at the breaker. There is no second fix wave.

Clean → delete `.delegate/<plan>/`. Git history is the record now. Sibling
directories belong to other plans.

Then `/publish`.

## Continuous Execution

Do not check in between tasks. "Should I continue?" and progress recaps waste
the user's time — they asked for the plan to be executed. Stop only for: a
`BLOCKED` you cannot resolve, a plan contradiction needing their ruling, or
completion.

## Rationalizations

| Excuse | Reality |
|---|---|
| "Close enough on spec compliance" | Spec gaps mean not done. Fix, or hit the cap and adjudicate. |
| "I'll just fix it myself, dispatching is overhead" | Your fixes skip review and pollute the context you need for coordination. |
| "One more round will converge" | Past the cap, rounds do not converge. The failure is structural. |
| "This finding is obviously wrong, drop it" | Adjudicate at the cap, in the ledger. Never silently. |
| "The fix was small, skip the re-review" | Unreviewed fixes are how regressions land. |
| "Reviews slow the loop down" | Without them the loop is unverified churn. |
| "Ledger bookkeeping is overhead" | It is what survives compaction. Without it you re-run finished work. |
| "`HEAD~1` is close enough for the diff" | It drops every commit but the last. Use the recorded BASE. |
| "Paste the prior tasks so it has context" | A real session hit 42k chars of dispatch, 99% pasted history. Brief only. |
