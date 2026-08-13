---
name: do
description: Universal feature-work driver — research → plan → implement → verify → PR, distilled from long production use. Use whenever the user says "let's work on N", "work on issue N", "do N", "implement N", "next task", "what's next", or hands you a task/issue to build, even if they don't say "skill". Works in any repo: discovers the repo's own test/lint/build gates and docs conventions instead of assuming a stack. Encodes the working contract: TDD (test first), GitHub-issue tracking, docs kept in sync, conventional commits, PR with screenshot for UI, standing rule commit+PR always / merge only on explicit user order. Supports worktrees or plain branches.
allowed-tools: Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(npx:*), Bash(cargo:*), Bash(go:*), Bash(uv:*), Bash(tsx:*), Bash(node:*), Bash(python:*), Bash(make:*), Read, Write, Edit, Glob, Grep, Agent, Skill, TaskCreate, TaskUpdate, TaskList
---

# /do — Universal Feature-Work Driver

Research → plan → implement → verify → PR, distilled from how this workflow
has been run in production. Repo-agnostic: it discovers each repo's own gates
and conventions instead of assuming a stack. Works in a worktree or on a plain
branch. Merge only when the user says "merge".

## Argument Parsing

`$ARGUMENTS` is one of:

- `N` — work GitHub issue #N start to finish (default full cycle)
- `N plan` — jump to plan
- `N implement` — jump to implement
- `N verify` — jump to verify
- `N pr` — jump to commit+PR (assumes implementation already verified)
- `N merge` — jump straight to merge (after CI green + user order)
- `--worktree` / `--wt` anywhere — use a git worktree instead of a branch in
  the main checkout

`ISSUE` = first arg. `PHASE` = second word (default `research`).
`MODE` = worktree if `--worktree`/`--wt` present, else branch.

## Standing Rules (non-negotiable, from user verbatim)

1. "always commit and pr work and i'll tell you when to close the pr or not" —
   **every completed work gets committed + PR'd. NEVER merge without the user
   explicitly saying so.**
2. Test everything: unit/component + e2e. **TDD — write the failing test first.**
3. Keep the repo's feature/coverage doc in sync with every change — if the repo
   has one (FEATURES.md, docs/features, a feature table in the README), update
   it; if it doesn't, don't invent one unasked.
4. Simplest thing that works; match existing style; surgical changes; no
   speculative code; no type-safety escapes (`as any`, `@ts-ignore`); no empty
   catch; bugfixes are minimal (never refactor while fixing).
5. Never `git add -A`. Stage explicit paths. No AI attribution in commits/PRs.

---

## Phase 0: Fetch Task + Discover the Repo

If `ISSUE` is a number:

```bash
gh issue view $ISSUE --json title,body,labels,state
```

Print a one-line summary. If the issue is vague, ask ONE clarifying question
before researching.

**Discover the repo's contract** (do this once per repo, reuse across tasks):

```bash
cat package.json        # scripts: test / typecheck / lint / build / e2e
ls .github/workflows/   # CI jobs = the real gates
ls Makefile go.mod Cargo.toml pyproject.toml 2>/dev/null
git log --oneline -10   # commit-message style (conventional? scopes?)
ls docs/                # feature/coverage doc conventions
```

From that, note: the test command, the lint/typecheck command, the e2e command,
the build command, CI job names, commit style, and whether the repo tracks
features in a doc. Run the base test suite once to get a green baseline.

**Set up the work surface:**

```bash
git switch main && git pull --ff-only
```

- `MODE=worktree`: `git worktree add .worktrees/$TASK main` then `git switch
  -c issue-$ISSUE-...` inside it. All subsequent commands run from the worktree
  dir.
- `MODE=branch`: `git switch -c issue-$ISSUE-$(echo "$TITLE" | tr '[:upper:] ' '[:lower:]-' | tr -cd '[:alnum:]-' | cut -c1-30)`.

Always pass the explicit working directory to every command (shell cwd can
drift). Never modify files outside the work surface during research/plan.

---

## Phase 1: Research

Fire 1–3 `explore` agents in parallel (background) to map the exact files the
change touches — current implementations, tests, fixtures, e2e assertions that
will break. Prompt structure: context / goal / downstream / request.

**Verify briefs against primary sources.** Task briefs, API maps, and migration
guides are hypotheses — read the actual files before writing code. Grep before
reading; batch reads; don't re-read files you just wrote.

When research is done: **compress** the exploration into a design summary before
planning. Stop and let the user sanity-check the design if it changes behavior
they've seen.

---

## Phase 2: Plan

Create a detailed todo list (todowrite) — atomic steps, each with WHERE/HOW/EXPECTED.
Mark one `in_progress` at a time, complete immediately after each step.

Decide delegation up front:

| Work | Delegate to |
|---|---|
| UI/UX/styling/layout | `task(category="visual-engineering", load_skills=["frontend"])` |
| Hard logic, spec/runtime changes | `task(category="deep")` or `ultrabrain` |
| Backend routes + tests | `task(category="deep")` |
| Trivial single-file edit | `task(category="quick")` |
| Exploration | `explore` (background, parallel) |

Delegate **independent units in parallel** (run_in_background=true), never
sequentially. Every delegation prompt must include: TASK / EXPECTED OUTCOME /
REQUIRED TOOLS / MUST DO / MUST NOT DO / CONTEXT (file paths + existing
patterns to follow). Vague prompts = rejected.

Process lesson: after a free-tier model retry, background task IDs (`bg_...`)
can 404. Collect output with the continuation session
(`task(task_id="ses_...")`) or `session_read` instead. Verify every delegated
diff yourself after the agent reports done — don't trust the summary.

---

## Phase 3: Implement

Follow the plan. For each todo:

1. **Write the failing test first** (unit for libs, component test for UI, or
   an e2e test for user flows) — then the minimal implementation that makes it
   pass.
2. Read files before editing. Match existing patterns (this repo's style is
   the contract: component conventions, selector/test conventions, persistence
   or storage helpers, toast/error conventions).
3. Keep code simple: minimum code, nothing speculative, no abstractions for
   single use. 200 lines that could be 50 → rewrite.

Implementation is done when: all planned todos complete, diagnostics clean on
changed files, unit+component tests green.

---

## Phase 4: Verify (the repo's gates, in order)

Run the gates you discovered in Phase 0 — typically:

```bash
<test command>          # unit + component
<lint/typecheck command>  # static gates
<build command>         # compiles
<e2e command>           # full user-flow suite (slowest, last)
```

Evidence required — **NO EVIDENCE = NOT COMPLETE**:

- File edits → `lsp_diagnostics` clean
- Unit/component suite → all pass (note the counts)
- Static gates → exit 0
- Build → exit 0
- E2E → all pass (retries absorb flakes)

Browser-e2e process lessons (from hard-won CI debugging):
- Monaco/code-editors virtualize — `toContainText` assertions must target lines
  inside the rendered fold, or scroll first.
- Debounced localStorage persistence needs a flush wait (`waitForFunction`)
  before `page.reload()` in e2e.
- Sidebars/tabs hidden behind a mode toggle — click the toggle first.
- Never `sleep` + poll — use `expect(...).toHaveText(text, { timeout })`.
- Slow runtime boots (WASM/Pyodide-class) vs short execution timeouts: give the
  boot its own budget (heartbeat/status protocol) so cold starts don't kill
  runs; CI runners have fewer cores — cap parallel workers in CI.

---

## Phase 5: UI Screenshot (only for UI changes)

If the change is user-visible, capture evidence for the PR:

1. Boot the app (the repo's dev command) in a PTY.
2. Drive with a browser-automation script (the repo's selector convention —
   `data-testid` or similar) to the feature state, screenshot to
   `/tmp/issue$ISSUE-*.png` (capture the meaningful states, e.g. expanded +
   collapsed, light + dark).
3. Attach to the PR: if the repo has a screenshots branch/asset convention use
   it (upload via API, reference the raw URL in the PR body); otherwise drag
   the PNGs into the PR body directly.
4. Kill the dev-server PTY when done.

---

## Phase 6: Docs + Commit + PR

Update the repo's feature/coverage doc (Phase 0) with the new feature row and
its test coverage, matching the doc's own convention. Keep it in sync with
code — it's a contract.

Commit + PR (standing rule — commit+PR **always**):

```bash
git add <explicit paths>   # NEVER -A
git commit -m "type(scope): summary"   # match the repo's commit style
git push -u origin issue-$ISSUE-...
```

Repo log style varies (`feat(web):`, `fix(runner):`, `feat(problems):`) —
mirror the scopes this repo uses. No AI attribution, no co-author.

```bash
gh pr create --title "$(git log -1 --pretty=%s)" --body /tmp/pr-body.md
```

PR body (`/tmp/pr-body.md`):
- `Closes #N` — **one keyword per line or comma-separated** if multiple issues
  (space-separated does NOT auto-close in GitHub)
- What changed (file-level summary)
- Verification: test counts, gates green
- Screenshots for UI changes

---

## Phase 7: CI + Report

```bash
gh pr checks $PR_NUMBER --watch
```

All CI checks must pass. On failure: `/investigate-ci` — download the failing
job's artifacts (check the workflow's upload path) and read the error context +
trace before touching code.

Then report to the user: what shipped, PR link, CI status. **Stop.** Do NOT
merge. The user decides merge timing — when they say "merge":

```bash
gh pr merge $PR_NUMBER --squash --delete-branch
```

If `MODE=worktree`, also clean up: `git worktree remove .worktrees/$TASK` after
merge (and `git worktree prune`).

---

## Key Rules

- **Never merge without the user saying so.** Report and wait.
- **Bugfix rule:** fix minimally, never refactor while fixing.
- **Refactor/feature split:** never mix refactoring and new behavior in one PR —
  two PRs, refactor merged first.
- **Uncommitted work is the live baseline:** `git status --short` + check target
  files before implementing. If deliverables already exist, verify against the
  spec instead of rebuilding.
- **Context hygiene:** compress closed exploration/implementation into summaries
  as you go — keep the window sharp for the verification phase.
- **Deliver evidence:** success banners and exit codes are not proof — inspect
  the artifact the way a real consumer does.
- **Concurrency with other work:** collaborators sometimes commit directly to
  main (not via PR). Always `git pull --ff-only` before branching and after
  merges; in a worktree, rebase onto main when it moves.
