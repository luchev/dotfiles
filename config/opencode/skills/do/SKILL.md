---
name: do
description: AIn't Code feature-work driver — research → plan → implement → verify → PR, the way this repo actually works. Use whenever the user says "let's work on N", "work on issue N", "do N", "implement N", "next task", "what's next", or hands you a GitHub issue to build, even if they don't say "skill". Encodes the repo contract: GitHub-issue tracking, TDD (test first, every feature covered), docs/FEATURES.md kept in sync (U/C/E/V legend), calm-minimal UI, conventional commits, PR with screenshot for UI, standing rule commit+PR always / merge only on explicit user order.
allowed-tools: Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(npx:*), Bash(tsx:*), Bash(node:*), Read, Write, Edit, Glob, Grep, Agent, Skill, TaskCreate, TaskUpdate, TaskList
---

# /do — AIn't Code Feature-Work Driver

Research → plan → implement → verify → PR, the way aintcode actually runs.
Branch from `main`, conventional commits, FEATURES.md in sync, CI green, PR up.
Merge only when the user says "merge".

## Argument Parsing

`$ARGUMENTS` is one of:

- `N` — work GitHub issue #N start to finish (default full cycle)
- `N plan` — jump to plan
- `N implement` — jump to implement
- `N verify` — jump to verify
- `N pr` — jump to commit+PR (assumes implementation already verified)
- `N merge` — jump straight to merge (after CI green + user order)

`ISSUE` = first arg. `PHASE` = second word (default `research`).

## Standing Rules (non-negotiable, from user verbatim)

1. "always commit and pr work and i'll tell you when to close the pr or not" —
   **every completed work gets committed + PR'd. NEVER merge without the user
   explicitly saying so.**
2. Test everything: unit/component + e2e. **TDD — write the failing test first.**
3. Update `docs/FEATURES.md` with every feature change (legend: U Vitest ·
   C Vitest+RTL · E Playwright · V verify:problems). One table row per feature,
   with the test file that covers it.
4. Simplest thing that works; match existing style; surgical changes; no
   speculative code; no `as any` / `@ts-ignore`; no empty catch; bugfixes are
   minimal (never refactor while fixing).
5. Never `git add -A`. Stage explicit paths. No AI attribution in commits/PRs.

---

## Phase 0: Fetch Task + Context

If `ISSUE` is a number:

```bash
gh issue view $ISSUE --json title,body,labels,state
```

Print a one-line summary. If the issue has no comments and is vague, ask ONE
clarifying question before researching (scope ambiguity costs more than a
question).

Create the work branch:

```bash
git switch main && git pull --ff-only
git switch -c issue-$ISSUE-$(echo "$TITLE" | tr '[:upper:] ' '[:lower:]-' | tr -cd '[:alnum:]-' | cut -c1-30)
```

All commands run from `/Users/z/aintcode` (the session cwd can drift — always
set the explicit workdir).

---

## Phase 1: Research

Fire 1–3 `explore` agents in parallel (background) to map the exact files the
change touches — current implementations, test files, fixtures, e2e assertions
that will break. Prompt structure: context / goal / downstream / request.

**Verify briefs against primary sources.** Task briefs, API maps, and migration
guides are hypotheses — read the actual files before writing code. Grep before
reading; batch reads; don't re-read files you just wrote.

When research is done: **compress** the exploration into a design summary before
planning. Stop and let the user sanity-check the design if it changes behavior
they've seen (e.g. a UI decision they'll care about).

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

1. **Write the failing test first** (unit for libs, RTL component test for UI,
   or a Playwright test for user flows) — then the minimal implementation that
   makes it pass.
2. Read files before editing. Match existing patterns (this repo is disciplined:
   calm-minimal design, `data-testid` selectors, `safeGet/safeSet` persistence,
   toast via sonner, conventional test style).
3. Keep code simple: minimum code, nothing speculative, no abstractions for
   single use. 200 lines that could be 50 → rewrite.

Implementation is done when: all planned todos complete, diagnostics clean on
changed files, unit+component tests green.

---

## Phase 4: Verify (all four gates)

```bash
npm test            # all workspaces (unit + component)
npm run typecheck   # all workspaces, tsc --noEmit
npm run verify:problems   # seed problems run against real runtimes
npm run test:e2e    # Playwright — build+preview :4173, ~42 tests, ~25s
```

Evidence required — **NO EVIDENCE = NOT COMPLETE**:

- File edits → `lsp_diagnostics` clean
- `npm test` → all suites pass (web ~134, server ~89, runner ~67)
- `npm run typecheck` → exit 0
- `npm run verify:problems` → "All seed problems verified"
- `npm run test:e2e` → all tests pass (retries:1 absorbs flakes)

E2E process lessons (from hard-won CI debugging):
- Monaco virtualizes — `toContainText` assertions must target lines inside the
  rendered fold (~12 lines), or scroll first.
- Debounced localStorage persistence (300ms) needs a flush wait
  (`waitForFunction`) before `page.reload()` in e2e.
- FileExplorer renders only after clicking `switch-files` (instructions mode
  default) — click it first.
- Never `sleep` + poll — use `expect(...).toHaveText(text, { timeout })`.
- Suite is parallel-safe (unique emails/slugs); CI caps workers at 2 (Pyodide
  boots hit the 5s execution budget on 2-vCPU runners — the booting-heartbeat
  fix gives boot a 30s budget, so this is mostly historical).

---

## Phase 5: UI Screenshot (only for UI changes)

User wants a screenshot in the PR for UI work. Process:

1. Boot the app: `npm run dev:admin` (ensures admin + runs server :8787 +
   web :5173) in a PTY, or reuse the e2e preview.
2. Drive with a Playwright script (data-testid selectors) to the feature state,
   screenshot to `/tmp/issue$ISSUE-*.png` (e.g. expanded + collapsed states).
3. Upload via GitHub Contents API to the **screenshots branch**:
   `docs/screenshots/issue$ISSUE-<name>.png`. Reference in the PR body as:
   `https://github.com/luchev/aintcode/raw/screenshots/docs/screenshots/<file>.png`
4. Kill the dev-server PTY when done.

---

## Phase 6: FEATURES.md + Commit + PR

Update `docs/FEATURES.md`: add the row(s) to the right table (B backend, X
execution engine, F frontend, D dev tooling) with the U/C/E/V coverage letters
and the test file names. Keep in sync with code — it's a contract.

Commit + PR (standing rule — commit+PR **always**):

```bash
git add <explicit paths>   # NEVER -A
git commit -m "type(scope): summary"   # conventional, matches repo log style
git push -u origin issue-$ISSUE-...
```

Repo log style: `feat(web): ...`, `fix(runner): ...`, `perf(tests): ...`,
`feat(problems): ...`, `test(web): ...`. No AI attribution, no co-author.

```bash
gh pr create --title "$(git log -1 --pretty=%s)" --body /tmp/pr-body.md
```

PR body (`/tmp/pr-body.md`):
- `Closes #N` — **one keyword per line or comma-separated** if multiple issues
  (space-separated does NOT auto-close in GitHub)
- What changed (file-level summary)
- Verification: test counts, gates green
- Screenshots (markdown raw-URL refs) for UI changes

---

## Phase 7: CI + Report

```bash
gh pr checks $PR_NUMBER --watch
```

All 5 checks must pass: TypeCheck · Tests · Verify Problems · Build Web · E2E
Tests. On failure: `/investigate-ci` — download the `e2e-test-results` artifact
(`gh run download <run> -n e2e-test-results -D /tmp/e2e-<n>`; path is repo-root
`test-results/`) and read the error-context.md + trace before touching code.

Then report to the user: what shipped, PR link, CI status. **Stop.** Do NOT
merge. The user decides merge timing — when they say "merge":

```bash
gh pr merge $PR_NUMBER --squash --delete-branch
```

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
- **Concurrency with other work:** the user sometimes commits directly to main
  (e.g. issue #86 landed without a PR). Always `git pull --ff-only` before
  branching and after merges.
