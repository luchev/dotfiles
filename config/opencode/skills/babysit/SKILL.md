---
name: babysit
description: Spawn a background agent that watches a PR through CI until it lands — polls checks, re-triggers infra flakes, fixes what it safely can, and pings you only for a restamp or a genuine failure. Use when the user says "babysit this PR", "watch PR N", or "keep an eye on CI".
allowedTools:
  - Bash(gh:*)
  - Bash(git:*)
  - Bash(cd:*)
  - Agent
  - SendMessage
  - TaskStop
---

# /babysit — Babysit a PR in a Background Agent

One long-lived agent watches a PR through CI to landing. It handles infra flakes on its
own and interrupts the user only for things that need a human.

## Argument Parsing

- `1234` — bare number
- `https://github.com/<owner>/<repo>/pull/1234` — full URL (a trailing `/files` is fine)

Parse: `PR` = digits, `REPO` = from the URL else the current repo, `WT_DIR` = second arg
else the worktree whose branch matches the PR head.

## Step 1: Gather context before spawning

Check these yourself — spawning a watcher onto a broken base just produces a loop of
failures no agent can fix:

- The branch has an upstream set (`git rev-parse --abbrev-ref '@{u}'`), or the push
  tooling will refuse.
- The base is not stale. Count commits behind: `git rev-list --count HEAD..origin/main`.
  A large number means setup-time checks will hard-fail on every SHA no matter how many
  times they are re-triggered. Rebase, re-verify locally, push, and only then spawn.

## Step 2: Kill any existing watcher for this PR

Two watchers on one PR will fight over re-triggers. `TaskStop` the old one first.

## Step 3: Spawn the agent

### 3a. The blocking-loop rule — most important

> Never end your turn while the PR is open and CI is unresolved. Work inside back-to-back
> blocking Bash calls. Each blocks for several minutes waiting for a state change, then
> returns; evaluate, immediately issue the next. That is how you poll for hours.

Give it this loop verbatim:

```bash
cd $WT_DIR
prev=""
for i in $(seq 1 20); do
  raw=$(gh pr checks $PR 2>/dev/null)
  bad=$(echo "$raw" \
    | awk -F'\t' '$2=="fail"||$2=="failure"||$2=="error"||$2=="cancelled"||$2=="timed_out"{print $1}' \
    | grep -viE 'Mergeable|Required Approvers')
  st=$(gh pr view $PR --json state,reviewDecision --jq '"\(.state) \(.reviewDecision)"' 2>/dev/null)
  cur="$bad|$st"
  if [ "$cur" != "$prev" ]; then echo "CHANGE: $cur"; prev="$cur"; fi
  if [ -n "$bad" ]; then echo "FAILING: $bad"; break; fi
  case "$st" in CLOSED*|MERGED*) echo "PR_STATE: $st"; break ;; esac
  sleep 30
done
```

### 3b. cwd resets

> The harness resets cwd between Bash calls. Start EVERY call with `cd $WT_DIR &&`, or
> `gh`/`git` fail with "not a git repository".

### 3c. Which checks matter

**Do not hardcode a job-name list** — it varies with what the PR touches, and a fixed
list silently misses the checks that matter. Use the generic filter above.

> Review gates (`Required Approvers`, `Mergeable`) pending or failing are NOT CI failures.
> Never try to "fix" them, and never disable a review requirement.

### 3d. Failure triage

| Signal | Class | Action |
|---|---|---|
| base far behind main | STALE BASE | rebase and re-push; amending does **not** move the base, so re-triggering can never fix it |
| cancelled, exit 130, preemption, runner lost | INFRA | re-trigger, at most 3 times |
| the same check red on unrelated PRs right now | INFRA | wait, report once |
| a test assertion, a compile error, a lint rule | REAL | do not re-trigger; report it |

**Compare a failing check's duration against a passing run of the same check.** A check
that fails far faster than its normal runtime aborted during setup — that is a
configuration or base problem, never a flaky test.

### 3e. Restamp rule

Any push that invalidates an approval means the user must restamp. Say so explicitly.

### 3f. Landing detection

Some hosts squash-merge out of band, so a landed PR can show **CLOSED, not MERGED**.
Before calling a PR abandoned, look for its commit on main
(`git log origin/main --grep "(#<N>)"`). Absence of a merge flag is not evidence.

### 3g. Bots and stacks

If the PR is a stack parent, publishing walks the whole tree. Tell the agent which PR is
the child, forbid touching it, and have it stop and report if an action would affect it.

### 3h. Notification policy — ONE LINE each

Message the user only for: restamp needed, a genuine failure it is not fixing, a fix it
made, PR landed, re-triggers exhausted, time limit hit.

```
✅ <PR url> — landed as <sha>
✅ <PR url> — CI green, missing: reviewers
❌ <PR url> — <check>: <one-clause cause>
⚠️ <PR url> — pushed <reason>, approval invalidated, needs restamp
```

A log excerpt is allowed only on a genuine failure, on following lines. Never a status
report, never a list of passing checks, never "still running".

**Never report a failure as an infra flake, or as "not caused by this PR", without naming
the evidence.** The same check failing across unrelated PRs right now counts. "It failed
fast", "it passed before", and "I found no record of it" do not. When the cause is
unknown, say it is unknown — a wrong flake call sends the user off to wait out a real,
fixable problem.

### 3i. Constraints

- Never `git push --force`. Use `--force-with-lease`, and stop and ask if the lease fails.
- Never add or remove PR labels
- Never touch files outside the PR's existing changed set without asking first
- Never modify the linked issue or ticket
- Stop and report at ~6 hours wall time

## Step 4: Report — ONE LINE, nothing else

Confirm the watcher is running and on which PR. No plan recap.
