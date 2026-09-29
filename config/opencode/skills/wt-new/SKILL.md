---
name: wt-new
description: Create a new sparse git worktree for feature development. Accepts a name or branch, an optional upstream branch for stacked work, and optional build targets/dirs to materialise. Creates the worktree under $REPO_ROOT/.worktrees/ named after the argument.
---

# /wt-new — Create a New Sparse Worktree

In a repo large enough that a full checkout is measured in gigabytes and minutes, a
worktree should be a **sparse checkout** — the handful of directories the task touches,
not the tree. Keep one full checkout elsewhere, parked on `main`, for the repo-wide
queries a sparse tree cannot answer itself.

## Argument Parsing

- `my-feature` — plain name, branch off main
- `my-feature upstream-branch` — stacked (second positional)
- `my-feature --upstream upstream-branch` — same, explicit flag
- `--target <build target>` — materialise that target's whole dependency closure (repeatable)
- `--dirs a,b,c` — materialise extra repo-relative dirs
- `--full` — escape hatch: no sparse checkout at all

Branch name is always `luchev/<name>`.

## Step 1: Run the script

```bash
~/.claude/scripts/wt-new.sh <NAME> [UPSTREAM_BRANCH] [--target <t>] [--dirs a,b]
```

Prefer `--target` when the task names a build target — the worktree then comes out
already buildable. Otherwise pass `--dirs` with the directory you will edit.

It prints the path, branch, upstream, and on-disk size. If the worktree already exists
it prints that and exits 0.

## Step 2: Widen on demand

Sparse checkouts fail loudly, never silently: the build reports a missing package and
`grep`/`find` simply do not see the dir. When that happens, widen:

```bash
~/.claude/scripts/wt-sparse-add.sh --target <build target>   # full dep closure
~/.claude/scripts/wt-sparse-add.sh path/to/dir               # one dir
```

**Commit first.** Widening reapplies the sparse checkout, which resets tracked paths in the
cone to HEAD — new files that are only staged or only on disk are deleted without warning.
Commit (or stash) before every widen; if files vanish mid-task, that is what happened.

Widen for the **test** target, not just the library: a library's dep closure is a strict
subset, so provisioning it guarantees a second round trip as soon as you run the tests. The
same goes for any toolchain binary the repo's documented commands invoke (coverage, lint) —
those build from their own trees, unrelated to yours.

Resolving a dependency closure needs the **full** checkout, because a sparse tree cannot
answer that query about code it does not have. If the full checkout is missing or itself
sparse, the script falls back to an auto-heal loop driven by the build's own
missing-package errors.

## How the sparse set is built

1. **Base dirs** — the build system's own directories (rules, tools, vendored deps,
   scripts, CI config), plus every top-level file, which cone mode gives for free.
2. **Bootstrap dirs** — the packages the build must load before it can compute anything
   at all: everything reachable through `load()`-style imports from the workspace root
   files, plus any in-repo labels external dependencies pull in. Compute these once and
   cache them, refreshing on an interval. Without them the build dies during setup,
   before it ever looks at your target.
3. **Your dirs** — `--dirs` and each `--target`'s dep closure.

## Troubleshooting

- The build fails computing the workspace/repository mapping — a **bootstrap** dir is
  missing, and the error names only the first one. Do not widen one dir at a time: each
  build is minutes long and there may be a dozen, so you chase the same error all
  afternoon. Regenerate the whole list at once, from the **full** checkout, and apply it:

  ```bash
  rm -f <bootstrap cache file>
  <bootstrap-generating script> <full checkout> > /tmp/bootstrap-dirs.txt
  cp /tmp/bootstrap-dirs.txt <bootstrap cache file>
  git -C <worktree> sparse-checkout add $(tr '\n' ' ' < /tmp/bootstrap-dirs.txt)
  ```

  Deleting the cache alone fixes nothing — the regenerating script must actually run and
  produce a non-empty file. Check `wc -l` on it before trusting a later widen; an empty
  cache silently yields a worktree whose build cannot bootstrap at all.
- **A cone that worked yesterday can break after a rebase.** The bootstrap set is a
  property of `main`, not of your branch, so someone else's commit can add a dir your cone
  lacks — it surfaces as the same mapping error, mid-publish, with no diff of your own.
  Same fix.
- Fastest recovery when another worktree already builds: copy its cone wholesale, rather
  than rebuilding it. `git -C <good-wt> sparse-checkout list > /tmp/cone.txt`, then
  `git -C <broken-wt> sparse-checkout set $(tr '\n' ' ' < /tmp/cone.txt)`. Commit first —
  `set` reapplies the cone and drops uncommitted files in paths it removes.
- A missing-package error during analysis — that is a **target** dep, not bootstrap.
  Widen with `wt-sparse-add.sh --target <the test target>`, not the library target.
- A grep finds nothing you expected — you are in a sparse tree. Search the full checkout
  instead, or widen.
- `fatal: '<branch>' is already checked out` — git allows a branch in exactly one
  worktree. Branch from it (`-b new-name <branch>`) or check it out detached.

## Publishing from a sparse worktree

Rebase onto **local** `main`, never `origin/main`:

```bash
git -C <full checkout> pull --ff-only   # bring local main up to date
git rebase main                         # NOT origin/main
```

Affected-target selection is normally computed from the diff against **local** `main`,
and then every target in that set is built. Rebasing onto `origin/main` while local `main`
lags leaves the intervening commits inside the diff, so the set balloons until it reaches
packages the cone never checked out — the failure reads as a missing package followed by
"no test targets were found, yet testing was requested". Rebasing onto local `main` makes
the merge-base exact, the set collapses to the package you changed, and the run proceeds
normally.

Do not reach for a flag that skips tests. It skips the repo validation the publish is
supposed to perform. If the set is still too wide after pinning the base, widen the cone
from the packages the error names.
