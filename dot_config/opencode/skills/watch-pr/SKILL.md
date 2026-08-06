---
name: watch-pr
description: Spawn a background agent that watches a GitHub PR until it lands — polls CI, re-triggers infra flakes, fixes what it safely can, and pings you for a restamp or a genuine failure. Use when the user says "monitor this PR", "watch PR N until it lands", "babysit my PR", or "keep an eye on CI for N".
allowedTools:
  - Bash(cd *)
  - Bash(gh *)
  - Bash(git *)
  - Bash(ls *)
  - Agent
  - SendMessage
  - TaskStop
---

# /watch-pr — Watch a PR in a Background Agent

Spawns one long-lived agent that watches a PR through CI to landing. It acts on
infra flakes silently and interrupts the user only for things needing a human.

## Argument Parsing

`$ARGUMENTS` is one of:

- `1234` — PR number, infer repo and worktree from the current dir
- `1234 /path/to/worktree` — PR number + explicit working dir
- `https://github.com/<owner>/<repo>/pull/1234` — full URL (a trailing `/files` is fine)

Parse: `PR` = digits. `REPO` = from the URL, else `gh repo view --json nameWithOwner --jq .nameWithOwner`.
`WT_DIR` = second arg, else the worktree whose branch matches the PR head.

## Step 1: Gather context

```bash
gh pr view $PR --json state,isDraft,reviewDecision,headRefOid,title,headRefName,labels,files
gh pr checks $PR | awk -F'\t' '$2!="pass"{printf "%s=%s\n",$1,$2}'
git worktree list
```

Note branch, head SHA, changed files, labels, and whether it is already
approved. The agent needs all of them.

**Find the worktree by branch, not by ticket name** — they often differ
(`me/PROJ-42-refactor` may live in `.worktrees/PROJ-42`). Verify
`git -C $WT_DIR rev-parse HEAD` equals the PR head and the tree is clean.
Check the upstream is set: `git -C $WT_DIR rev-parse --abbrev-ref '@{u}'`.

**No worktree?** Create one and WAIT for it to finish before spawning:

```bash
git worktree add $REPO_ROOT/.worktrees/<name> <branch>   # run_in_background if slow
```

The worktree appears in `git worktree list` long before checkout completes.
Gate on the background command's completion, never on the listing, or the
checkout will overwrite the agent's work.

**Stop here** if the PR is already closed — verify how it ended (Step 3f)
rather than spawning.

**Stop here** if the PR is green and merely unreviewed. A watcher cannot
produce an approval; say so instead of spawning one.

## Step 2: Kill any existing watcher

One watcher per PR. If a prior `Monitor` or watcher agent for this PR is
running, `TaskStop` it first — two watchers double-push and fight each other.
If it is already watched and healthy, say so in one line and do not spawn a
second.

## Step 3: Spawn the agent

`Agent` with `subagent_type: general-purpose`, `model: sonnet`,
`name: pr-<PR>-watcher`, `run_in_background: true`.

The prompt MUST contain all of the following. Each was learned from a watcher
that broke without it.

### 3a. The blocking-loop rule — most important

> Never end your turn while the PR is open and CI is unresolved. Work inside
> back-to-back blocking Bash calls. Each blocks ~10 minutes waiting for a state
> change, then returns; you evaluate and immediately issue the next one. That is
> how you poll for hours.

Give it this loop verbatim:

```bash
cd $WT_DIR
prev=""
for i in $(seq 1 20); do
  bad=$(gh pr checks $PR 2>/dev/null \
    | awk -F'\t' '$2=="fail"||$2=="failure"||$2=="error"||$2=="cancelled"||$2=="timed_out"{print $1}' \
    | grep -viE 'Mergeable|Required Approvers|Review')
  st=$(gh pr view $PR --json state,reviewDecision --jq '"\(.state) \(.reviewDecision)"' 2>/dev/null)
  cur="$bad|$st"
  if [ "$cur" != "$prev" ]; then echo "CHANGE: $cur"; prev="$cur"; fi
  if [ -n "$bad" ]; then echo "FAILING: $bad"; break; fi
  case "$st" in CLOSED*|MERGED*) echo "PR_STATE: $st"; break ;; esac
  sleep 30
done
```

### 3b. cwd resets

> The harness resets cwd between Bash calls. Start EVERY call with
> `cd $WT_DIR &&`, or `gh`/`git` fail with "not a git repository".

### 3c. Which checks matter

**Do not hardcode a job-name list — it varies by what the PR touches.** A fixed
list silently misses the checks that matter for this diff. Use the generic
filter from 3a, and treat only required/blocking checks as failures.

> Review gates — `Required Approvers`, `Mergeable`, anything named `Review` —
> are not CI failures. Never try to fix them, and never try to bypass them.

### 3d. Failure triage

| Signal | Class | Action |
|---|---|---|
| exit 130, "cancellation signal", runner preemption, job cancelled | INFRA | re-trigger, max 3 times |
| `No space left on device`, runner `context deadline exceeded`, image pull failure | INFRA | same |
| "outdated base", "rebase onto latest main", merge conflict with base | STALE BASE | `git fetch origin main` (its own call), `git rebase origin/main`, push |
| generated-file diff (codegen, lockfile, formatter) | BUILD | re-run the generator, commit, push |
| real test failure, compile error, lint error | CODE | see below |

Re-trigger an infra flake with the forge's own rerun rather than a push, when
one exists — it does not invalidate approvals:

```bash
gh run rerun --failed <run-id>
```

Fall back to `git commit --amend --no-edit && git push --force-with-lease`
only when the check has no rerun path. Never a bare `--force`.

**Calibrate fix latitude to the diff.** A YAML deletion or a docs tweak cannot
break a build — for those, tell the agent never to guess, just report. A code
change, a new script, or a new build-file entry genuinely can — for those,
allow an unambiguous fix confined to the PR's own files, verified by running
the failing test locally, then push. Name the allowed files explicitly in the
prompt.

> A failure in a package this PR does not touch means something else landed on
> the base branch. Do NOT guess. Report and stop.

### 3e. Restamp rule

> Check `reviewDecision` every poll. If it is `APPROVED` and you then push
> anything — including an amend for an infra re-trigger — that invalidates the
> approval. Push, then IMMEDIATELY report that a restamp is needed.

### 3f. Landing detection

`MERGED` is the normal signal. Some merge queues squash out of band and leave
the PR `CLOSED` instead — never conclude from `CLOSED` alone that the work was
abandoned. Confirm against the base branch:

```bash
cd $WT_DIR
git fetch origin main          # its own call — never chained
git log origin/main --oneline -30 -- <changed-dir> | grep '(#<PR>)'
```

Grepping the squash subject for `(#<PR>)` is more reliable than grepping for a
content token.

### 3g. Bots and stacks

- **A bot amends the branch** (autofix, formatter, dependency bumper) ⇒ before
  any push, `git fetch origin <branch>` (own call) and compare local HEAD to
  `gh pr view --json headRefOid`. If they differ, do NOT push —
  `git reset --hard origin/<branch>` and re-evaluate. A head change the agent
  did not cause is not a failure.
- **Stack parent** ⇒ pushing rewrites every descendant. Tell the agent which PR
  is the child, forbid touching it, and have it stop and report if its action
  would affect the child.

### 3h. Notification policy — ONE LINE each

`SendMessage` to `main` only for: restamp needed, a genuine failure it is not
fixing, a fix it made, PR landed, 3 infra re-triggers exhausted, 6h limit.

```
✅ <PR url> — landed as <sha>
✅ <PR url> — CI green, missing: reviewers
❌ <PR url> — <check>: <one-clause cause>
⚠️ <PR url> — pushed <reason>, approval invalidated, needs restamp
```

A log excerpt is allowed only on a genuine failure, on following lines. Never a
status report, never a list of passing checks, never a recap of its own
instructions. No "still running" messages.

### 3i. Constraints

- Never `git push --force`. `--force-with-lease` only, and if the lease is
  rejected, stop and report — the remote moved.
- Never add or remove PR labels
- Never touch files outside the PR's existing changed set without asking
- Never edit the linked issue or ticket
- Keep the PR body as it is; do not append sections
- Stop and report at ~6 hours wall time

## Step 4: Report — ONE LINE, nothing else

No preamble, no table, no bullet list, no explanation of what the agent will do.

```
✅ <PR url> — <what is still missing>
```

Examples:

```
✅ https://github.com/acme/widget/pull/1210 — CI green, missing: reviewers
❌ https://github.com/acme/widget/pull/1208 — build failed (runner cancelled), re-triggering
```

Add a second line only for a decision the user must make (a label you did not
add, a stack hazard). Never restate the agent's brief.

## Notes

- The agent cannot satisfy required approvals — a human still has to review.
- Every push resets CI, so a green result observed before a push is stale.
- If the repo merges via a queue label and the label is absent, the PR sits
  green and unlanded forever. Flag it; do not add the label without asking.
