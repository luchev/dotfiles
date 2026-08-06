---
name: verify
description: >
  Comprehensive pre-completion verification: tests, linting, build, security, git state, docs.
  Use before marking work done, creating PRs, or deploying. Runs 10 verification categories.
  Trigger when user says "verify this is done", "check everything", "ready to ship",
  or after implementing a feature to ensure nothing was missed.
---

# Verify Command

**Description**: Comprehensive verification before completing development work to ensure quality and correctness.

## The Iron Law

```
NO COMPLETION CLAIM WITHOUT FRESH EVIDENCE
```

If you have not run the command in this message, you cannot say it passes.
Violating the letter of this rule is violating its spirit — a paraphrase, an
implication, or an expression of satisfaction all count as the claim.

## The Gate Function

Before any status claim:

1. **Identify** — what command proves this?
2. **Run** — the full command, fresh, not a subset
3. **Read** — full output, exit code, failure count
4. **Compare** — does the output actually confirm the claim?
5. **Then** state the claim *with* the evidence

Skipping a step is not verifying, it is asserting.

## What Counts as Evidence

| Claim | Evidence | Not evidence |
|---|---|---|
| Tests pass | Test output, 0 failures | An earlier run, "should pass" |
| Linter clean | Linter output, 0 errors | A partial check, one file |
| Build succeeds | Build exit 0 | Linter passing — it does not compile |
| Bug fixed | The original symptom retested | The code changed |
| Regression test works | Red-green proven: revert fix → test fails → restore → passes | The test passes once |
| Subagent finished | The diff on disk | The agent's report |
| Data imported | Reading it back through a consumer's path | The importer's "imported: N" |
| Requirements met | Line-by-line against the plan | Tests passing |

## Red Flags — Stop

- "should", "probably", "seems to", "looks right"
- Satisfaction before evidence — "Great!", "Perfect!", "Done!"
- About to commit, push, or open a PR without a fresh run
- Taking a subagent's or an API's word for its own success
- Partial verification standing in for the whole
- "Just this once" / wanting the work to be over

## Rationalizations

| Excuse | Reality |
|---|---|
| "Should work now" | Run it. |
| "I am confident" | Confidence is not evidence. |
| "Just this once" | No exceptions — the exception is where the bug ships. |
| "The linter passed" | The linter does not compile or execute anything. |
| "The agent said success" | Verify independently, on disk. |
| "It exited 0" | Exit 0 means the process ended, not that it did the thing. |
| "Partial check is enough" | Partial proves the part you checked. |
| "Different words, so the rule does not apply" | Spirit over letter. |

## When to Use

- Before marking work complete
- Before creating a pull request
- After implementing a plan
- Before deploying
- After a large refactor

## The Ten Categories

Use the project's own commands — read `Makefile`, `package.json`, `justfile`, or
CI config to find them. The shapes below are placeholders, not commands to run
literally.

| # | Category | What proves it | Look for |
|---|---|---|---|
| 1 | Tests | `<test command>`, 0 failures | Skipped tests without a reason, new code with no test, untested error paths |
| 2 | Coverage | `<coverage command>` against the project's threshold | Coverage that dropped, not just its absolute value |
| 3 | Lint & types | `<lint command>`, `<typecheck command>` | Suppressions added in this change |
| 4 | Build | `<build command>`, exit 0, from clean | New warnings; a build that only works incrementally |
| 5 | Security | `<audit command>`, plus a secrets scan | Credentials in code, fixtures, or logs; new untrusted input paths |
| 6 | Git | `git status`, `git diff --cached`, `git log` | Debug code, commented-out code, stray TODOs, large files, unrelated changes |
| 7 | Docs | Diff against README, CHANGELOG, API docs | Behaviour changed but docs did not |
| 8 | Functionality | Run it — happy path, an error path, a boundary | Symptoms the tests do not assert |
| 9 | Migrations & data | Migration up *and* down against a scratch DB | Irreversible migrations; no rollback path |
| 10 | Dependencies | Lockfile diff | Unintended version bumps, new transitive deps |

Categories 9 and 10 apply only when the change touches them. The rest always do.

### Secrets scan

The one check worth spelling out, because it is the most expensive to miss and
the same everywhere:

```bash
git diff --cached | grep -inE '(api[_-]?key|secret|token|password|BEGIN [A-Z ]*PRIVATE KEY)'
```

A hit is not automatically a leak — but you read every one before proceeding.

## Report

State each category as claim plus evidence, or say it was not applicable. Never
report a category you did not run.

```
Tests:     142 passed, 0 failed
Lint:      clean
Build:     exit 0
Security:  no findings; secrets scan clean
Git:       3 commits, no debug code, no large files
Docs:      README updated (new flag documented)
Manual:    happy path + invalid input verified
Skipped:   migrations (none in this change), deps (lockfile unchanged)
```

If something failed, that is the report. Say what failed, quote the shortest
decisive line, and stop — do not bury it under the categories that passed.

## Related

- `/review` — judgement about the change; this skill is evidence about its state
- `/publish` — runs the test gate itself before opening a PR
- `/tdd` — red-green is what makes a regression test count as evidence here
