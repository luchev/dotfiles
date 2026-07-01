---
name: wt-new
description: Create a new git worktree for feature development. Accepts a name or branch, with an optional upstream branch for stacked work. Creates worktree at $REPO_ROOT/.worktrees/<name>.
---

# /wt-new — Create a New Worktree

## Argument Parsing

- `my-feature` — plain name, branch off main
- `my-feature upstream-branch` — stacked (second positional arg)
- `my-feature --upstream upstream-branch` — same, explicit flag

`NAME` = first arg. `UPSTREAM_BRANCH` = value after `--upstream` or second positional if it contains `/` or looks like a branch.

Branch name: `<git-username>/<name>` where `git-username` = `git config user.name | tr ' ' '-' | tr '[:upper:]' '[:lower:]'`. If unset, use `<name>` directly.

## Step 1: Compute paths

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
GIT_USER=$(git config user.name | tr ' ' '-' | tr '[:upper:]' '[:lower:]' 2>/dev/null || echo "")
BRANCH="${GIT_USER:+$GIT_USER/}$NAME"
WT_DIR="$REPO_ROOT/.worktrees/$NAME"
```

## Step 2: Check if exists

```bash
test -d "$WT_DIR"
```

If exists, print and exit:
```
Worktree already exists:
  Path:   $WT_DIR
  Branch: $BRANCH
```

## Step 3: Create worktree

**No upstream (branch off main):**
```bash
mkdir -p "$REPO_ROOT/.worktrees"
git -C "$REPO_ROOT" fetch origin main
git -C "$REPO_ROOT" worktree add -b "$BRANCH" "$WT_DIR" origin/main
```

**Stacked on upstream:**
```bash
mkdir -p "$REPO_ROOT/.worktrees"
git -C "$REPO_ROOT" worktree add -b "$BRANCH" "$WT_DIR" "$UPSTREAM_BRANCH"
git -C "$WT_DIR" branch --set-upstream-to="$UPSTREAM_BRANCH" "$BRANCH"
```

## Step 4: Report

```
Worktree created:
  Path:     $WT_DIR
  Branch:   $BRANCH
  Upstream: $UPSTREAM_BRANCH   ← or "origin/main"
```
