---
name: gh-status
description: Show status of all your open GitHub PRs — title, link, CI check status, review/approval state, unresolved comments, and auto-merge. Use when the user says "gh status", "pr status", "check my PRs", "what's the state of my PRs", or "show my open PRs".
allowedTools:
  - Bash(gh *)
  - Bash(bash ~/.dotfiles/claude/zellij-status.sh status *)
---

# /gh-status — Open PR Dashboard

No arguments. Reports all open PRs authored by you (`@me`) across the current repo (or use `--search` scope below for all repos). Uses the public `gh` CLI — run from inside a repo, or `gh` infers it.

---

## Step 1: Fetch open PRs

```bash
bash ~/.dotfiles/claude/zellij-status.sh status "fetching open PRs"
```

```bash
gh pr list --author @me --state open \
  --json number,title,url,reviewDecision,mergeStateStatus,autoMergeRequest,isDraft
```

To span every repo you have PRs in (not just the current one):

```bash
gh search prs --author @me --state open --json number,title,url,repository
```

Collect each PR `number` (and `repository` if using search — pass `-R owner/repo` to the calls below).

---

## Step 2: Fetch details per PR (in parallel)

For each PR number, run **in parallel**:

```bash
gh pr checks <NUMBER>                                   # CI check runs
gh pr view <NUMBER> --json reviewDecision,reviews,statusCheckRollup,autoMergeRequest
gh pr view <NUMBER> --json comments,reviewThreads 2>/dev/null \
  || gh api repos/{owner}/{repo}/pulls/<NUMBER>/comments
```

(Add `-R owner/repo` when iterating across multiple repos.)

---

## Step 3: Report

```bash
bash ~/.dotfiles/claude/zellij-status.sh status ""
```

Print a single summary table, then a blockers section:

```
| PR | Title | CI | Approved | Comments | AutoMerge |
|----|-------|----|----------|----------|-----------|
| [#N](url) | <short title, ≤40 chars> | ✅/❌/⏳ | ✅/❌/⏳ | 💬 X (Y need reply) | ✅/— |

### Blockers
- **#N** — <one line: what's preventing merge>
- **#N** — Ready to merge 🚀
```

**CI column** — worst status across all checks (`gh pr checks` / `statusCheckRollup`):
- All passed → ✅
- Any failed → ❌ (name the check)
- Any in-progress, none failed → ⏳

**Approved column** (from `reviewDecision`):
- `APPROVED` → ✅
- `CHANGES_REQUESTED` → ❌
- `REVIEW_REQUIRED` / pending → ⏳

**Comments column** — analyze review threads (`reviewThreads`, else the comments API):
- Count unresolved threads (`isResolved == false`, not outdated)
- A thread **needs a reply** if the last comment in it is NOT from you
- Show `💬 X (Y need reply)` if any unresolved — e.g. `💬 5 (3 need reply)`
- Show `—` if none

**AutoMerge column:** `✅` if `autoMergeRequest`/`autoMergeRequest != null`, else `—`.

**Draft PRs:** prefix the title with `[draft]`.
