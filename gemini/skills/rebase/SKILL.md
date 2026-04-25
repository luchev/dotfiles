---
name: rebase
description: Rebase branch(es). No args or a branch name rebases the current branch against its upstream with AI conflict resolution. Pass "all" to rebase all worktrees in dependency order (topological sort, parents before children, cascades failures).
---

# /rebase — Rebase Branch(es)

- (empty) → rebase current branch against its upstream
- `all` → rebase all worktrees in topological order

---

## Single Branch

### Step 1: Determine branch and upstream

```bash
git branch --show-current
git rev-parse --abbrev-ref @{u} 2>/dev/null  # fallback: origin/main
```

Print: `Rebasing <branch> against <upstream> …`

### Step 2: Fetch + rebase

```bash
git fetch origin
git rebase <upstream>
```

If exit 0 → done. If non-zero → apply **[Conflict Resolution]** below.

### Step 3: Report

```
Rebase complete.
  <branch>  rebased against <upstream>  [N conflicts auto-resolved]
```

---

## All Worktrees

### A1: List worktrees

```bash
git worktree list --porcelain
```

Parse `(worktree_path, branch)` per stanza. Record `REPO_ROOT` (first stanza), `MAIN_WT_PATH`. Skip bare / detached-HEAD / primary worktree from loop.

### A2: Collect upstreams

```bash
git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads \
  | grep -v '^main ' | grep -v '^master '
```

Build `UPSTREAM[branch]`. Branches with no upstream: skip with `WARNING: <branch> has no upstream — skipping.`

> **Note**: Use `grep -E` or `awk` for filtering — never `rg -E` (that flag sets encoding, not a regex pattern).

### A3: Topological sort

Normalize each branch's upstream to local parent:
- `origin/main`, `main`, or empty → **main** (root)
- `origin/<X>` where `<X>` is in worktree set → `<X>`
- Local `<X>` in worktree set → `<X>`
- Otherwise → **main**

BFS level-order from main. Process all of level N before N+1.

### A4: Fetch + update main

```bash
git -C <REPO_ROOT> fetch origin main
git -C <MAIN_WT_PATH> rebase origin/main
```

If this fails: abort with FATAL — all subsequent rebases depend on main.

### A5: Rebase each in order

Maintain `failed_set`. For each `(branch, path)` in BFS order (skip main):

1. If parent in `failed_set`: mark `branch` as skipped, continue
2. Determine target: if `UPSTREAM[branch]` starts with `origin/` use it; else use `normalized_parent(branch)`
3. `git -C <path> rebase <target>` — on failure: apply **[Conflict Resolution]**. If still fails: add to `failed_set`.

### A6: Report

```
Rebase complete.

Successfully rebased (N):
  - feature/foo    rebased against origin/main
  - feature/bar    rebased against feature/foo  [1 conflict auto-resolved]

Failed / Skipped (M):
  - feature/baz    unresolvable conflict in src/foo/bar.go
  - feature/qux    skipped — parent feature/baz failed
```

---

## Conflict Resolution Procedure

`$DIR` = worktree path (`.` for single, specific path for `all`).

**CR1:** Find conflicts:
```bash
git -C $DIR diff --name-only --diff-filter=U
```

**CR2:** For each conflicting file:
1. Read the file (`<<<<<<<`/`=======`/`>>>>>>>` markers present)
2. **Resolvable**: logically independent changes (different functions, struct fields, imports, purely additive) → edit to remove markers, then `git -C $DIR add <file>`
3. **Not resolvable**: overlapping/contradictory changes or intent unclear → `git -C $DIR rebase --abort`. Record: `"unresolvable conflict in <file>"`. Return to caller.

**CR3:** After staging all resolved files:
```bash
git -C $DIR rebase --continue
```

If another conflict round: repeat CR1–CR3. If `rebase --continue` fails: `git -C $DIR rebase --abort`, record failure.
