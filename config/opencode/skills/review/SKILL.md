---
name: review
description: >
  Comprehensive code review with blocking issues, suggestions, nitpicks, and questions.
  Use when reviewing PRs, auditing implementations, or providing structured code feedback.
  Trigger when user says "review this code", "review the PR", "check this implementation",
  "give me feedback on", or invokes /review on a branch or file set.
---

# Review Command

Review code for correctness, security, and maintainability. Report only findings
you can defend.

For acting on review feedback you have *received*, use `/review-reply`.

## When to Use

- Reviewing a PR or diff
- Auditing an implementation
- Self-review before publishing
- The final gate in `/delegate`

## Review Process

### Step 1: Understand the intent

Read the PR description and the linked issue. Know what the change is *supposed*
to do before judging whether it does. A review that never states the intent is
reviewing lines, not a change.

### Step 2: Get the code

```bash
gh pr checkout <N>          # or: git fetch origin pull/<N>/head:pr-<N>
git diff main...HEAD --stat
```

Read the diff with surrounding context (`git diff -U10`), not just the changed
lines. Most defects live in the interaction between new and existing code.

### Step 3: Run what the project runs

Tests, linter, build — whatever the repo actually uses. A review that did not
run the suite cannot claim the change is safe, only that it reads well.

### Step 4: Review in layers

Each pass covers the whole diff, in this order. Mixing them means style comments
crowd out architectural ones.

1. **Approach** — is this the right change at all? Wrong-layer fixes and
   unnecessary abstraction are found here or not at all.
2. **Correctness** — logic, edge cases, error paths, concurrency, resource
   lifetimes, off-by-one, nil/empty/zero handling.
3. **Security** — untrusted input reaching a sink; injection, path traversal,
   deserialization; authn/authz on every new entry point; secrets in code,
   logs, or fixtures.
4. **Tests** — do they cover the change, and would they fail if it regressed?
   See `tdd/references/writing-good-tests.md` for what makes a test real.
5. **Quality** — naming, duplication, dead code, comments that restate the code.

### Step 5: Filter, then report

Apply the Confidence Filter below, then write the report.

## Confidence Filter

Score every candidate finding before reporting it. Report only those at **80 or above**.

| Score | Meaning |
|---|---|
| 100 | Certain defect. Traced the failing path in the code; can state concrete inputs and the wrong result. |
| 75 | Very likely wrong, but one assumption is unverified (a callee's behaviour, a config value). |
| 50 | Suspicious. Could be correct depending on context not read. |
| 25 | Style preference or speculation dressed as a bug. |
| 0 | No evidence — pattern-matched on a name or a shape. |

Rules:
- Score against the code, not the diff. A line that looks wrong in isolation and is
  correct in context is a 25, not a 75.
- To claim 100, write the failure scenario first: inputs → wrong output. If it can't
  be written, the finding isn't 100.
- Nitpicks and praise are exempt from the filter — they aren't defect claims. Everything
  under Blocking and Strong Suggestions is subject to it.
- Discard sub-80 findings silently. Listing "possible issues" with low confidence shifts
  verification onto the reader and is what makes reviews ignorable.

## Comment Types

| Marker | Use for | Contract |
|---|---|---|
| 🚫 **BLOCKING** | Bugs, security holes, breaking changes without a migration path, failing tests | Must be resolved before merge |
| ⚠️ **SUGGESTION** | Performance, missing tests, weak error handling, quality problems | Address or explain why not |
| 💡 **NITPICK** | Style, minor cleanups | Explicitly optional |
| ❓ **QUESTION** | Intent or approach unclear | Needs an answer, not a change |
| ✅ **NICE** | Solutions worth repeating | No action |

Every Blocking and Suggestion states the failure it prevents, not the rule it
breaks. "Violates SRP" is not a finding. "A panic here leaves the mutex locked
and the next caller deadlocks" is.

## Report Format

````markdown
## Assessment

[What the change does, and the one thing that most matters about it]

**Recommendation**: Approve / Request changes / Comment

## Findings

### `path/to/file.go:45` — <short title>
🚫 **BLOCKING**: <the defect>

<failure scenario: inputs → wrong result>

<suggested fix, if short and you are confident>

### `path/to/other.go:12` — <short title>
⚠️ **SUGGESTION**: ...

## Questions

1. ❓ ...
````

Order findings by severity, then by file. Anchor every one to `file:line` — an
unanchored finding is a complaint.

## Size

- Under 200 lines: one pass.
- 200–500: layered passes as above.
- Over 500: say so and ask for a split before reviewing. Review quality falls off
  a cliff past this, and approving a diff you skimmed is worse than declining it.

## Giving Feedback

Be specific and explain the why. Point at the failing case rather than the
principle. Acknowledge work worth repeating — sparingly, so it means something.

Do not comment vaguely ("this looks wrong"), block on personal preference,
nitpick in volume, or list problems without saying what would resolve them.

## Related

- `/review-reply` — receiving and acting on review feedback
- `/analyze` — deep analysis before a large review
- `/verify` — evidence gate before claiming the change is done
