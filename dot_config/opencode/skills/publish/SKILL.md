---
name: publish
description: Full publish pipeline — rebases, updates the commit message, runs tests, then creates or updates the GitHub PR using gh CLI. Use when ready to ship changes.
---

# /publish — Full Publish Pipeline

Rebase → commit message → tests → create/update PR.

## Argument Parsing

- (empty) — current branch
- `--draft` — PR as draft
- `--skip-tests` — skip test step
- `--no-auto-merge` — disable auto-merge label (default: ON)

Parse: `DRAFT`, `SKIP_TESTS`, `AUTO_MERGE` (default true).

## Step 1: Sanity check

```bash
git status --short && git branch --show-current
```

Warn on uncommitted changes; ask to proceed. Do not auto-stage.

## Step 1b: Confirm the base

```bash
git rev-parse --abbrev-ref '@{u}' 2>/dev/null
git merge-base --fork-point origin/main HEAD 2>/dev/null
```

The base is what this branch forked from — for stacked work that is the parent
branch, not `main`. If the upstream is unset or disagrees with the fork point,
ask before continuing: `"This branch looks like it forked from <X> — correct?"`
A PR opened against the wrong base is expensive to unwind.

## Step 2: Rebase

Invoke `/rebase`. If conflict unresolvable: stop.

## Step 3: Update commit message

Invoke `/commit-msg`.

## Step 4: Detect changed packages

```bash
git diff @{u}..HEAD --name-only 2>/dev/null | grep '\.go$' \
  | awk -F/ '{OFS="/"; NF--; print}' | sort -u
# Fallback if @{u} not set: git diff origin/main..HEAD ...
```

## Step 5: Run tests (skip if `--skip-tests`)

```bash
go test ./...
```

Stop on failure.

## Step 6: Determine PR action

```bash
BRANCH=$(git branch --show-current)
gh pr view --head "$BRANCH" --json number 2>/dev/null
```

No existing PR → **create**. PR exists → **update**.

## Step 7: Publish

**Create:**
```bash
TITLE=$(git log -1 --format="%s")
BODY=$(git log -1 --format="%b")

gh pr create \
  --title "$TITLE" \
  --body "$BODY" \
  ${DRAFT:+--draft}
```

After PR creation, if `AUTO_MERGE` is true:
```bash
PR_NUM=$(gh pr view --head "$BRANCH" --json number --jq '.number')
gh pr edit "$PR_NUM" --add-label AutoMerge
```

**Update (push + sync body):**
```bash
git push origin HEAD
gh pr edit --title "$TITLE" --body "$BODY"
```

A rejected push means the remote moved — someone pushed, or a stack parent was
rewritten. Fetch and find out what changed. `--force-with-lease` is the only
force to reach for, and only after the rebase in Step 2 is what made the
histories diverge. If the lease itself is rejected, stop and report; do not
escalate to a bare `--force`.

## Step 7b: Verify what actually landed

A success banner is not evidence. Read the PR back before reporting anything:

```bash
gh pr view "$PR_NUM" --json body,isDraft,baseRefName,labels \
  --jq '"len=\(.body|length) draft=\(.isDraft) base=\(.baseRefName) labels=\([.labels[].name]|join(","))"'
```

A body length of ~150 chars means only the subject line survived — the description was
dropped. With label-parsing publish tooling that happens when the commit body has no
`Summary:` label; fix the commit message and repair the PR with
`gh pr edit <N> --body-file <file>`, preserving any trailing `## Stack` section the tool
appended. Such tooling typically does **not** regenerate an existing body after an amend,
and a refresh flag may report "No changes to publish" once the branch is pushed.

Report Step 8 from these values, not from the publish command's output.

## Step 8: Summary

```
Publish complete.
  Rebase:  OK (rebased against origin/main)
  Commit:  abc1234  Short message
  Tests:   passed
  PR:      https://github.com/<owner>/<repo>/pull/<N> (created/updated)
```

Keep the worktree. Review feedback gets addressed there; it is cleaned up by
`/clean` once the PR lands.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "Tests passed earlier this session" | They passed on a different tree. Step 2 rebased. Run them again. |
| "`--skip-tests` just this once, it is a small change" | Then it costs seconds. The flag is for when CI is the gate, not for haste. |
| "The base is obviously main" | Not for stacked branches. Confirm the fork point. |
| "The push was rejected, force it" | The remote moved. Find out why first. |
| "`gh pr create` exited 0, so the body is fine" | Exit 0 says the request was accepted. Step 7b reads back what landed. |
| "The description is close enough to the commit body" | They are the same text by construction. If they differ, something dropped it. |
