---
name: commit-msg
description: Generate a git commit message from branch changes and git history. Amends the latest commit or creates an empty placeholder. Does not push or publish.
---

# /commit-msg — Generate Commit Message

Generates a commit message whose body doubles as a PR description. **Never pushes.**

## Argument Parsing

- (empty) — auto-detect from current branch
- `--amend` — force amend mode
- `--empty` — force empty-commit placeholder

`FORCE_AMEND`, `FORCE_EMPTY`.

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

## Step 3: Write the commit message

**Golden rule: be as short as possible while including all meaningful information a reviewer needs.**
Every sentence must earn its place. Cut adjectives, cut restatements of the code, cut anything obvious from the diff.

**Subject:** ≤72 chars, imperative, no period.

**Body — prefer this compact form:**
```
## Summary
1–2 sentences max. What changed and why, in plain English.

## Implementation
Bullet points only. One line per non-obvious technical decision.
Skip anything self-evident from the diff.
```

**Rules:**
- Merge `## Why` into `## Summary` unless the motivation is non-obvious
- Omit any section that adds no information beyond the diff itself
- No padding phrases ("This PR introduces…", "In order to…", "As part of…")
- `## Implementation` bullets: lead with the file/function, state the decision, stop

## Step 4: Determine mode

```bash
git log @{u}..HEAD --oneline 2>/dev/null | wc -l
```

- Count 0 or `FORCE_EMPTY` → empty-commit
- Count ≥1 or `FORCE_AMEND` → amend

## Step 5: Apply

```bash
git commit --amend -m "<message>"        # amend mode
git commit --allow-empty -m "<message>"  # empty-commit mode
```

Print: `Applied in <mode>. Commit: abc1234  <subject line>`
