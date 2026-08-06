---
name: improve
description: >
  Make targeted code improvements: quality, performance, maintainability, best practices.
  Use when user wants code made better without changing behavior.
  Trigger when user says "improve this", "refactor", "clean up", "optimize", "make this better",
  "reduce technical debt", or "modernize". Does not change external behavior.
---

# Improve Command

Make code better without changing what it does. Behaviour-preserving by
definition — the moment behaviour changes, this is a feature or a bugfix and
belongs in `/tdd` or `/debug`.

## When to Use

- Refactoring complex code
- Improving readability
- Optimizing a measured bottleneck
- Reducing technical debt
- Modernizing legacy patterns

## The Standard

From the repo's own engineering principles — the bar, not suggestions:

- **Minimum code.** 200 lines that could be 50 → rewrite. No abstraction for a
  single use. No error handling for impossible states. No speculative
  extensibility.
- **Surgical changes.** Touch only what you must. Match the surrounding style.
  Do not "improve" adjacent code because you are already in the file.
- **Clean up your own orphans.** A helper your change made unreachable goes with
  it. Pre-existing dead code stays — that is a separate change.
- **Comments explain why.** Delete any comment that restates the code.

The most common failure of this skill is scope creep: a request to simplify one
function becomes a rewrite of its module. If you want that, say so and let the
user decide.

## Process

### 1. Establish the baseline

You cannot claim an improvement without a before. Run the tests and record that
they pass. For a performance change, record the actual measurement — a
benchmark, a timing, a profile. Without a number, "optimization" is decoration.

If the code has no tests, that is the first finding. Characterize the current
behaviour with a test before touching it; otherwise the refactor is unverifiable
by construction.

### 2. Prioritize

| Impact | Effort | Verdict |
|---|---|---|
| High | Low | Do it now |
| High | High | Plan it — probably its own change |
| Low | Low | Do it if you are already in the file |
| Low | High | Leave it alone |

"Impact" is measured on the reader and on the failure rate, not on aesthetics.

### 3. Improve in steps

One improvement per commit, tests green at each. A chain of small verified steps
survives a bisect; one large rewrite does not.

```bash
git checkout -b improve/<what>
# change one thing
<test command>
git commit -m "refactor: <the one thing>"
```

Never fold an unrelated fix into a refactor commit. If you find a real bug while
refactoring, stop and surface it — fixing it silently inside a
"behaviour-preserving" change hides it from review.

### 4. Prove it

Re-run the baseline. Tests still green, and for performance work, the number
moved in the direction you claimed. A refactor that made the code prettier and
the benchmark slower is not an improvement.

## Checklist

- [ ] All existing tests still pass
- [ ] No new warnings
- [ ] Behaviour genuinely unchanged, or the change called out explicitly
- [ ] Performance same or better, measured if that was the goal
- [ ] Coverage maintained
- [ ] Orphans from this change removed
- [ ] Diff as small as the improvement allows

## After

- `/verify` — evidence that nothing broke
- `/publish` — open the PR
