---
name: commit-msg
description: Generate a git commit message from branch changes and git history. The body doubles as a PR description (works directly with `gh pr create`). Amends the latest commit or creates an empty placeholder. Does not push or publish.
allowed-tools: Bash(git:*), Read
---

# /commit-msg — Generate Commit Message

Generates a commit message whose body also works as the PR description (e.g. `gh pr create --fill` reads the commit body). **Never pushes.**

## Argument Parsing

- (empty) — auto-detect issue context from `TICKET.md` if present
- `<ISSUE-ID>` — reference this issue in the body
- `--amend` — force amend mode
- `--empty` — force empty-commit placeholder

`ISSUE=[A-Z]+-[0-9]+` (or any tracker id), `FORCE_AMEND`, `FORCE_EMPTY`.

## Step 1: Analyze changes

```bash
git diff @{u}...HEAD  # fallback: git diff origin/main...HEAD
```

Identify changed files, packages, scope, and overall impact.

## Step 2: Learn from git history

```bash
git log -n 20 --no-merges \
  --pretty=format:"COMMIT_START|%h|%as|%s%n%b" \
  -- "$(git diff @{u}...HEAD --name-only 2>/dev/null | head -1 | awk -F/ 'NF>2{OFS="/"; NF-=2; print}' || echo '.')" \
  | awk -v RS='COMMIT_START' 'length() > 200'
```

Match the tone, verbosity, and technical detail of recent commits.

## Step 3: Load issue context (optional)

```bash
test -f TICKET.md && cat TICKET.md
```

If an issue ID is found (argument or `TICKET.md` first line), use it for the "why" and reference it in the body. No external fetch — work from the local file and the diff.

## Step 4: Write the commit message

**Golden rule: the reader is a busy reviewer who will also read the diff. Write only what the diff cannot tell them — mainly *why*.**

**Hard budget — a message over this is a bug in the output:**
- Body: **≤ 12 lines total**, including blank lines and headings.
- Opening: **1–3 sentences**, no heading above it.
- Bullets: **≤ 5**, one line each, ≤ 120 chars.
- Total body ≤ ~120 words.

**Subject:** ≤72 chars, imperative, no period, no issue prefix.

**Body — this shape, nothing else:**
```
Why this change is needed, and what it does. 1-3 sentences.

- Non-obvious decision or gotcha (only if the diff doesn't show it)
- Verified: <command that was run>

<ISSUE-ID>
```
Drop the bullet list entirely when there is nothing non-obvious. Drop the issue
line when there is no issue. Headings (`## Intent`, `## Changes`, `## Test Plan`)
are **not** used — the shape above is already scannable.

**Never include:**
- Evidence dumps: backtest tables, per-zone/per-host numbers, log excerpts, metric peaks. State the conclusion ("thresholds don't hold outside the OCI zones") and let the reviewer ask.
- Historical narrative: what a previous PR/diff did, how the code got here, quotes from old descriptions. One clause max if it's the actual reason.
- Follow-up work not in this change. That belongs in a ticket or the PR comments.
- Justification of choices nobody disputed, or restatement of what a bullet already said.
- Padding phrases ("This PR introduces…", "In order to…", "As part of…"), and the issue title verbatim.

**Include:** the reason the change exists, and any decision a reviewer could
reasonably get wrong on their own. Everything else is in the diff.

> Step 2's "match the tone of recent commits" applies to vocabulary and
> formatting only. Never inherit another commit's verbosity — this budget wins.

### Step 4b: If the repo's publish tooling parses field labels

Some publish tooling builds the PR description by parsing the commit message for **field
labels** rather than taking the body verbatim. Under that tooling an unlabelled prose body
is silently discarded and the PR ships with only its subject line. Keep everything above —
the budget, the why-first opening, the bullets — but wrap it in the labels:

```
<subject>

Summary:
<the 1-3 sentence opening, then the bullets>

Test Plan:
<what was run to verify; omit the "- Verified:" bullet above when using this>

Issues: <TRACKER-KEY>
```

Use the tracker's fully-qualified key, not a bare id — the field is usually what makes the
reference render as a link. Do not write literal `##` headings; this tooling adds them.

Detect this case from the repo's own publish workflow and conventions; the exact label
names are per-tool. Elsewhere, use the unlabelled shape above.

## Step 5: Determine mode

```bash
git log @{u}..HEAD --oneline 2>/dev/null | wc -l
```

- Count 0 or `FORCE_EMPTY` → empty-commit
- Count ≥1 or `FORCE_AMEND` → amend

## Step 6: Apply

```bash
git commit --amend -m "<message>"        # amend mode
git commit --allow-empty -m "<message>"  # empty-commit mode
```

Print: `Applied in <mode>. Commit: abc1234  <subject line>`
