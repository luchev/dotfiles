---
name: gh-status
description: Show status of all open GitHub PRs — title, link, unresolved comments, CI check status, approval state, and assignees. Use when the user says "gh status", "pr status", "check my PRs", "what's the state of my PRs", or "show my open PRs".
allowedTools:
  - Bash(gh:*)
---

# /gh-status — Open PR Dashboard

No arguments. Reports every PR the user has open.

## Step 1: List the open PRs

```bash
gh search prs --author=@me --state=open --json repository,number,title,updatedAt
```

If the host's search API is flaky, fall back to `gh pr list --author @me --state open`
per repo you care about.

## Step 2: Fetch details in parallel

For each PR, one call:

```bash
gh pr view <N> --repo <owner>/<repo> \
  --json title,url,state,isDraft,reviewDecision,latestReviews,statusCheckRollup,assignees,comments
```

Read from it:

- **CI** — `statusCheckRollup`: any `FAILURE`/`ERROR` is red, any `PENDING` is running,
  everything `SUCCESS` is green. Name the failing checks, not just the colour.
- **Approval** — `reviewDecision` (`APPROVED` / `CHANGES_REQUESTED` / `REVIEW_REQUIRED`).
  Some hosts leave this empty even when the PR is approved; when it is empty, say
  "unknown", never "not approved".
- **Unresolved comments** — count review threads that are not resolved.
- **Assignees / reviewers** — flag a PR with none, that is usually why it is stuck.

## Step 3: Report

One line per PR, worst first, each with its link:

```
❌ <url> — Build failed: <check names>
⏳ <url> — CI running (<n>/<m> checks)
⚠️  <url> — green, no reviewers assigned
✅ <url> — green, approved, ready to land
```

Group by state and keep it to one screen. If a PR is a draft, say so — a draft with no
reviewers is waiting on the author, not on anyone else.
