---
name: analyze
description: >
  Comprehensive code and architecture analysis: architecture, quality, performance, security, dependencies.
  Use when user wants deep understanding of a codebase or preparation for refactoring.
  Trigger when user says "analyze this", "audit the code", "review the architecture",
  "find issues", "what's wrong with this codebase", or before major refactoring work.
---

# Analyze Command

Build an accurate picture of a codebase and report what is actually wrong with
it, ranked by consequence.

`/review` judges a change. This judges a system.

## When to Use

- Understanding an unfamiliar codebase
- Auditing architecture before a large refactor
- Hunting a class of problem (security, performance) rather than a single bug
- Answering "what's wrong with this?"

## Step 1: Scope it

Analysis without a scope produces a survey nobody acts on. Before reading
anything, pin down:

- **Boundary** — whole repo, one service, one module?
- **Aspect** — which of the six types below?
- **Purpose** — refactor prep, incident follow-up, onboarding, due diligence?

The purpose determines what counts as a finding. For refactor prep, coupling
matters and a slow endpoint does not. Ask if it is not stated.

## Step 2: Pick the type

| Type | Answers |
|---|---|
| Architecture | What are the components, how do they depend on each other, where are the layering violations? |
| Code quality | Where is the complexity, duplication, and dead code concentrated? |
| Performance | Where does time and memory actually go, under what load? |
| Security | Where does untrusted input reach a dangerous sink, and what is unauthenticated? |
| Test coverage | What is untested, and are the existing tests real? |
| Dependencies | What is outdated, unused, vulnerable, or license-incompatible? |

More than one type at once means a shallower pass on each. Prefer depth.

## Step 3: Gather evidence

Use the project's own tooling — read the `Makefile`, CI config, or task runner
to find it. Typical shapes: a line counter, the dependency lister, coverage,
the audit command, the profiler, the linter with machine-readable output.

Tools measure. They do not conclude. Every finding a tool reports gets confirmed
by reading the code before it enters the report — a linter's "high complexity"
on a table-driven switch is not a finding.

For anything about *behaviour under load*, measure it. Performance claims from
reading code are guesses.

## Step 4: Find the patterns

The value of an analysis is not the list of instances; it is the pattern behind
them. Twelve places that forget to close a resource is one finding — a missing
convention — not twelve.

Look for: repeated shapes, inconsistencies between modules that should match,
layering violations, and the places where the code disagrees with its own docs.

## Step 5: Prioritize

| Severity | Meaning |
|---|---|
| Critical | Security hole, data loss risk, or an outage waiting for load |
| High | A real bug, or a bottleneck with measured cost |
| Medium | Maintainability — the thing that makes the next change expensive |
| Low | Style, consistency, preference |

Rank by consequence, not by how easy the finding was to spot. A report that
leads with naming conventions and buries an auth gap has failed regardless of
how complete it is.

Apply `/review`'s Confidence Filter to every finding: score it, and drop
anything under 80 silently. A speculative finding in an audit is worse than in a
review — it gets copied into a ticket and outlives the reasoning.

## Step 6: Report

Read [references/report-templates.md](references/report-templates.md) for the
shape matching your analysis type, and the full write-up template.

Every finding carries: location (`file:line`), what breaks, and what to do about
it. A finding without a recommendation is an observation, and observations do
not get fixed.

Close with an effort-ranked recommendation list — immediate, near term, later —
so the reader can act on the first item without reading the rest.

## After

- `/improve` — execute the maintainability findings
- `/plan` — turn a large set of findings into sequenced work
- `/debug` — chase a specific defect the analysis surfaced
