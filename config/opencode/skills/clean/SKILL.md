---
name: clean
description: Clean up worktrees and branches. Without args, cleans only the current worktree/branch. With "all", fetches main, rebases all active worktrees, and removes all merged ones.
---

# /clean — Clean Up Worktrees and Branches

## Argument Parsing

- (empty) — single mode: current worktree/branch
- `branch-name` — single mode: target a specific branch
- `all` — full mode

## Ownership Rule

Only remove worktrees this setup created — those whose path is under
`.worktrees/` or `worktrees/`. Anything else in `git worktree list` belongs to
the host environment (an IDE, a sandbox, a session harness) and is left alone
even when its branch is merged. Report it instead:
`"<path> is merged but externally managed — leaving in place."`

---

## Single Mode

### S1: Identify target

```bash
# No args: use current worktree/branch
git rev-parse --show-toplevel  # → WT_PATH
git branch --show-current      # → BRANCH
```

Stop if `BRANCH` is `main`/`master`. Verify worktree path exists.

### S2: Check merged / abandoned

```bash
git fetch origin main
git log HEAD ^origin/main --oneline  # empty = merged (covers squash merges)
gh pr view --head "$BRANCH" --json state,mergedAt \
  --jq '"state=\(.state) merged=\(.mergedAt // "null")"' 2>/dev/null
```

- **Merged**: log is empty
- **Abandoned**: PR state=CLOSED, mergedAt=null
- **Neither**: print status and stop

### S3: Check uncommitted changes

```bash
git -C "$WT_PATH" status --short
```

Ignore git-internal files: `AUTO_MERGE`, `COMMIT_EDITMSG`, `FETCH_HEAD`, `HEAD`, `MERGE_RR`, `ORIG_HEAD`, `commondir`, `gitdir`, `index`, `index.lock`, `logs/`. If real changes remain, show the diff and stop — do not remove. Removal of a dirty worktree is a data-loss action: it happens only after the user, having seen the diff, asks for it in so many words.

### S4: Re-point stacked children

```bash
git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads \
  | awk -v b="$BRANCH" '$2 == b {print $1}'
# Find grandparent (fallback: main):
git branch --format='%(upstream:short)' --list "$BRANCH"
# Re-point each child before deletion:
git branch --set-upstream-to=main <child>
```

### S5: Remove

```bash
REPO_ROOT=$(git -C "$WT_PATH" rev-parse --show-superproject-working-tree 2>/dev/null \
            || git -C "$WT_PATH" rev-parse --show-toplevel)
cd "$REPO_ROOT"
git worktree remove "$WT_PATH"
git worktree prune
git branch -d "$BRANCH"          # -D if squash-merged
```

---

## Full Mode (`/clean all`)

### A1: List worktrees

```bash
git worktree list --porcelain
```

Skip main/primary worktree (no branch or branch=main/master). Record `(path, branch)` for each remaining.

### A2: Rebase all

Invoke `/rebase all`. Wait for completion.

### A3: Check merge / abandoned status

For each worktree:
```bash
git -C <path> log HEAD ^origin/main --oneline
gh pr view --head "<branch>" --json state,mergedAt \
  --jq '"state=\(.state) merged=\(.mergedAt // "null")"' 2>/dev/null
```

### A4: Check uncommitted changes

Same ignore list as S3. Treat worktree as clean if only git-internal files appear.

### A5: Report

| Worktree Path | Branch | Rebased? | Merged? | Abandoned? | Clean? |
|---|---|---|---|---|---|

If no merged/abandoned worktrees: "Nothing to clean up." and stop.

### A6: Confirm

```
Found N worktree(s) ready to remove:
  - /path (branch: name) — merged
  - /path (branch: name) — abandoned (PR closed, not merged)

Remove all of them? (yes / select / skip)
```

For dirty merged/abandoned worktrees: show diff and ask separately. Do NOT remove active (unmerged) worktrees.

### A7: Remove

```bash
git worktree remove <path>   # if this fails, report why - never force
git worktree prune
```

### A8: Delete branches + re-point children

Same re-pointing logic as S4 for each branch, then:
```bash
git branch -d <branch>   # -D if squash-merged; do NOT delete remote branches
```

### A9: Summary

```
Cleaned up N worktree(s):
  - /path (branch: name) — worktree removed, local branch deleted
  - /path (branch: name) — ... re-pointed child → grandparent
```

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "The PR is up, so the worktree is clutter" | Review feedback gets fixed in that worktree. It stays until the work lands. |
| "This other worktree looks stale, clean it too" | Only `.worktrees/`/`worktrees/` paths are ours. The rest belong to the host. |
| "`git log HEAD ^origin/main` is empty, obviously merged" | It is also empty for a branch that never had commits. Check the PR state too. |
| "The uncommitted changes are probably junk" | Show the diff and stop. You do not know what is in it. |
| "`git worktree remove` failed, so force it" | A failing remove means state you have not accounted for. Diagnose it. |
| "Delete the remote branch too, it is merged" | Never. Remote branch deletion is the forge's job or the user's. |
| "The child branch will find its own parent" | It will not. Re-point children before deleting the parent, or the stack breaks. |
