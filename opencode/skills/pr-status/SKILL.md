---
name: pr-status
description: Show status of all your open GitHub PRs — title, link, CI check status, approval state, and unresolved comments. Use when the user says "pr status", "check my PRs", or "show my open PRs".
---

# /pr-status — Open PR Dashboard

No arguments. Detects the current GitHub user automatically.

---

## Step 1: Detect user and fetch open PRs

```bash
GH_USER=$(gh api user --jq '.login')
gh pr list --author "$GH_USER" --state open \
  --json number,title,url,headRefName,labels \
  --jq '.[]'
```

If no PRs: print `No open PRs found.` and stop.

---

## Step 2: Fetch details in parallel

For each PR `NUMBER`, run **in parallel**:

```bash
# CI check status
gh pr checks $NUMBER --json name,state,conclusion,detailsUrl

# Review state
gh pr view $NUMBER --json reviews,reviewDecision,comments,labels,autoMergeRequest
```

---

## Step 3: Report

Print a single summary table, then a blockers section:

```
| PR | Title | CI | Approved | Comments | AutoMerge |
|----|-------|----|----------|----------|-----------|
| [#N](url) | <short title, ≤40 chars> | ✅/❌/⏳ | ✅/❌/⏳ | 💬 X (Y need reply) | ✅/— |

### Blockers
- **#N** — <one line: what's preventing merge>
- **#N** — Ready to merge 🚀
```

**CI column** — show worst status across all **required** checks only:
- All required passed → ✅
- Any required failed → ❌ (name the check)
- Any required in-progress, none failed → ⏳

**Approved column:**
- Required approvals met → ✅
- `CHANGES_REQUESTED` → ❌
- Waiting → ⏳

**Comments column:** count unresolved review threads:
- Show `💬 X (Y need reply)` if any unresolved — where "needs reply" means the last comment in the thread is not from `$GH_USER`
- Show `—` if no unresolved comments

**AutoMerge column:** ✅ if `autoMergeRequest` is set, `—` otherwise.

**Blockers section:** one line per PR. If nothing blocks, say "Ready to merge 🚀".
