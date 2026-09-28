---
name: investigate-ci
description: Investigate why a PR is failing in CI. Fetches GitHub check runs, drills into failing workflows (logs and annotations), and diagnoses the root cause of each failure.
---

# /investigate-ci — Analyze CI Failures

## Argument Parsing

- `<PR_NUMBER>` — GitHub PR number (required)
- `[owner/repo]` — repository (default: detected from `git remote get-url origin`)

`PR_NUMBER` = first positional arg. `REPO` = second positional arg or auto-detected.

---

## Step 1: Detect repo and fetch PR context

```bash
# Auto-detect repo from remote if not provided
REPO=$(git remote get-url origin 2>/dev/null \
  | sed 's|.*github.com[:/]\(.*\)\.git|\1|; s|.*github.com[:/]\(.*\)|\1|')

# Fetch PR metadata and check runs in parallel
gh pr view $PR_NUMBER --repo "$REPO" \
  --json title,state,headRefName,headSha,statusCheckRollup

gh pr checks $PR_NUMBER --repo "$REPO" \
  --json name,state,conclusion,startedAt,completedAt,detailsUrl
```

---

## Step 2: Triage check runs

Collect only **failing checks** (conclusion: `failure`, `timed_out`, `cancelled`, `action_required`).

Classify by check type:
| Pattern | Type |
|---|---|
| GitHub Actions workflow | Actions |
| External CI (Buildkite, CircleCI, Jenkins) | External CI |
| Code review gate | Gate |
| Coverage check | Coverage |

---

## Step 3: Analyze each failure

### 3a. GitHub Actions

```bash
# Get the run ID from the details URL or:
gh run list --repo "$REPO" --commit "$HEAD_SHA" --json databaseId,name,conclusion,url

# Get failed job logs
gh run view $RUN_ID --repo "$REPO" --log-failed
```

For each failed job, look for:

| Symptom | Classification |
|---|---|
| Test assertion, `FAIL`, `--- FAIL:` | **Test failure** |
| `exit code 1` in build step | **Build failure** |
| `cancelled` with no error | **Infra: cancelled** — retry |
| Timeout / deadline exceeded | **Infra: timeout** |
| Linter errors | **Lint failure** |
| Coverage below threshold | **Coverage failure** |
| Missing approval / CODEOWNERS | **Gate failure** |

```bash
# Also check annotations
gh api repos/$REPO/check-runs/$CHECK_RUN_ID/annotations
```

### 3b. External CI

If the check links to an external service (Buildkite, etc.), fetch the URL via `gh api` or report the URL for manual inspection. Extract the error from the check's `output.summary` if available:

```bash
gh api repos/$REPO/check-runs/$CHECK_RUN_ID --jq '.output.summary'
```

### 3c. Gate failures

Read the check's `output.text` for required reviewers, CODEOWNERS paths, or test-plan requirements:

```bash
gh api repos/$REPO/check-runs/$CHECK_RUN_ID --jq '.output.text'
```

---

## Step 4: Report

Output only failures. Keep entries tight.

**Report only what this run's output says.** Three rules, each learned from getting it
wrong while polling a stack:

- **A green belongs to a commit, not a PR.** Any push — rebase, amend, restack — resets
  every check. Discard every prior result for that branch and say the checks restarted.
- **Diff against the previous run before writing "newly green" or "now cleared".** A
  completed check re-appears every poll with an identical duration string, which reads
  like stale data; an unchanged row means unchanged, not resolved. If a row is still in
  this run's output, it is still true.
- **Enumerate every non-passing row**, not just the interesting one — an aggregate check
  pending behind a job is easy to drop from the summary.

A bot check whose findings are not reachable (no PR comments, no API, an auth-walled
dashboard) is reported as unreadable with its `details_url`. Never infer the content from
the diff's subject matter, and probe each channel once rather than every poll.

```
## CI: PR #<N> — <Title>

### <Check Name> — <Classification>
**Fix:** <one line>
<2-4 line log excerpt>

---

### Action items
<Numbered, ordered by priority>
```

**Common patterns:**
- Cancelled with no error → infra, rerun: `gh run rerun $RUN_ID --repo $REPO --failed`
- Test failure → fix the test or the code
- Lint failure → run linter locally and fix
- Coverage drop → add tests for new code
- Missing approval → request review from CODEOWNERS

If all checks pass: print `CI: PR #<N> — All checks passed ✅`
