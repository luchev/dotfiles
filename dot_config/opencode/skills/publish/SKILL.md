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
- `--no-auto-merge` — disable auto-merge (default: ON)

Parse: `DRAFT`, `SKIP_TESTS`, `AUTO_MERGE` (default true).

## Step 1: Sanity check

```bash
git status --short && git branch --show-current
```

Warn on uncommitted changes; ask to proceed. Do not auto-stage.

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
  ${DRAFT:+--draft} \
  ${AUTO_MERGE:+--auto-merge}
```

**Update (push + sync body):**
```bash
git push origin HEAD
gh pr edit --title "$TITLE" --body "$BODY"
```

## Step 8: Summary

```
Publish complete.
  Rebase:  OK (rebased against origin/main)
  Commit:  abc1234  Short message
  Tests:   passed
  PR:      https://github.com/<owner>/<repo>/pull/<N> (created/updated)
```
