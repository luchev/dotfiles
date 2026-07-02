---
name: commit-msg
description: Generate a git commit message from branch changes and git history. The body doubles as a PR description (works directly with `gh pr create`). Amends the latest commit or creates an empty placeholder. Does not push or publish.
allowedTools:
  - Bash(git *)
  - Read
  - Bash(bash ~/.dotfiles/opencode/zellij-status.sh status *)
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
bash ~/.dotfiles/opencode/zellij-status.sh status "analyzing diff"
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

```bash
bash ~/.dotfiles/opencode/zellij-status.sh status "drafting commit message"
```

**Golden rule: be as short as possible while including all meaningful information a reviewer needs.**
Every sentence must earn its place. Cut adjectives, cut restatements of the code, cut anything obvious from the diff.

**Subject:** ≤72 chars, imperative, no period, no issue prefix.

**Body — prefer this compact form:**
```
1–2 sentences max. What changed and why, in plain English.

## Implementation
Bullet points only. One line per non-obvious technical decision.
Skip anything self-evident from the diff.

## Issue
<ISSUE-ID>   (omit this section if there is no associated issue)
```

**Rules:**
- Lead with what changed and why; merge motivation into the opening sentences unless it's non-obvious enough to warrant its own line.
- Omit any section that adds no information beyond the diff itself.
- No padding phrases ("This PR introduces…", "In order to…", "As part of…").
- No restating the issue title verbatim.
- `## Implementation` bullets: lead with the file/function, state the decision, stop.
- If tests were run, add them as a bullet under `## Implementation` (e.g. `- Verified: \`npm test\` passes`).

## Step 5: Determine mode

```bash
git log @{u}..HEAD --oneline 2>/dev/null | wc -l
```

- Count 0 or `FORCE_EMPTY` → empty-commit
- Count ≥1 or `FORCE_AMEND` → amend

## Step 6: Apply

```bash
bash ~/.dotfiles/opencode/zellij-status.sh status "committing"
git commit --amend -m "<message>"        # amend mode
git commit --allow-empty -m "<message>"  # empty-commit mode
```

Print: `Applied in <mode>. Commit: abc1234  <subject line>`

```bash
bash ~/.dotfiles/opencode/zellij-status.sh status ""
```
