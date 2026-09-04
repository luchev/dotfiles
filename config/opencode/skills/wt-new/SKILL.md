---
name: wt-new
description: Create a new sparse git worktree for feature development. Accepts a name or branch, an optional upstream branch for stacked work, and optional Bazel targets/dirs to materialise. Creates the worktree under $REPO_ROOT/.worktrees/ named after the argument.
---

# /wt-new — Create a New Sparse Worktree

Worktrees are **sparse checkouts**. A full go-code worktree is ~17G / 1.6M files; a
sparse one is ~1.4G / 85k files and takes seconds instead of minutes. The full tree
lives once, in `~/go-code`, which stays on `main`.

## Argument Parsing

- `my-feature` — plain name, branch off main
- `my-feature upstream-branch` — stacked (second positional)
- `my-feature --upstream upstream-branch` — same, explicit flag
- `--target //pkg:target` — materialise that target's whole Bazel dep closure (repeatable)
- `--dirs a,b,c` — materialise extra repo-relative dirs
- `--full` — escape hatch: no sparse checkout at all

Branch name is always `luchev/<name>`.

## Step 1: Run the script

```bash
~/.claude/scripts/wt-new.sh <NAME> [UPSTREAM_BRANCH] [--target //pkg:t] [--dirs a,b]
```

Prefer passing `--target` when the ticket names a Bazel target — the worktree then
comes out already buildable. Otherwise pass `--dirs` with the service dir you will edit.

It prints the path, branch, upstream, and on-disk size. If the worktree already exists
it prints that and exits 0.

## Step 2: Widen on demand

Sparse checkouts fail loudly, never silently: Bazel says
`no such package 'src/...'` and `grep`/`find` simply do not see the dir. When that
happens, widen:

```bash
~/.claude/scripts/wt-sparse-add.sh --target //pkg:target   # full dep closure
~/.claude/scripts/wt-sparse-add.sh src/code.uber.internal/foo/bar   # one dir
```

`--target` resolves the closure with `bazel query buildfiles(deps(...))` run in
`~/go-code` (the full checkout), because a sparse tree cannot answer that query itself.
If `~/go-code` is missing or itself sparse, it falls back to an auto-heal loop driven by
Bazel's own `no such package` errors.

## How the sparse set is built

1. **Base dirs** — `rules tools third_party patches bin scripts dockerfiles uber pkg
   build .buildkite .github`, plus every top-level file (cone mode gives those for free).
2. **Bootstrap dirs** — the `//src`, `//config`, `//idl`, `//udeploy` dirs Bazel must
   have before it can even compute the main repo mapping (everything reachable through
   `load()` from WORKSPACE/MODULE.bazel/rules/tools/third_party, plus the `//src` labels
   loaded by external repos such as `rules_go` → `gomock.bzl`). Computed by
   `~/.claude/scripts/sparse-bootstrap.sh`, cached at
   `~/.claude/cache/go-code-sparse-bootstrap.txt`, refreshed if older than 7 days.
   Without these, Bazel dies at "Error computing the main repository mapping" before it
   ever looks at your target.
3. **Your dirs** — `--dirs` and each `--target`'s dep closure.

## Troubleshooting

- `Error computing the main repository mapping: ... is not a package` — the bootstrap
  cache is stale. Delete `~/.claude/cache/go-code-sparse-bootstrap.txt` and re-run.
- `no such package 'src/...'` during analysis — widen with `wt-sparse-add.sh`.
- A grep across `src/` finds nothing you expected — you are in a sparse tree. Search
  `~/go-code` instead, or widen.
- `fatal: '<branch>' is already checked out` — git allows a branch in exactly one
  worktree. Branch from it (`-b new-name <branch>`) or check it out detached.

## Publishing from a sparse worktree

Publish with `arh publish --no-test`.

`arc unit` (which `arh publish` runs) computes its affected-target set from the diff against
**local** `main`, then builds every one of those targets. In a sparse worktree that fails two
ways: local `main` drifts behind `origin/main`, which inflates the set until it reaches
packages like `eats-web-feed` that were never checked out, and even a correctly-sized set can
pull in `//idl/...` paths the cone does not cover. The failure looks like
`no such package '...'` followed by `No test targets were found, yet testing was requested`.

Keeping `~/go-code` fast-forwarded (`git -C ~/go-code pull --ff-only`) right before publishing
shrinks the set enough to work sometimes, but it races anything else committing to `main`.
`--no-test` is the reliable answer — run the tests yourself against the target first, and CI
runs the full set regardless.
