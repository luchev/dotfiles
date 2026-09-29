---
description: Every claim carries a clickable proof link, and root-cause claims get red-teamed before they ship.
alwaysApply: true
---

# Evidence: Proof Links and Adversarial Challenge

Applies always, to every model, agent, subagent, and tool call.

## 1. Every claim carries a clickable proof link

A described query the reader would have to reconstruct is not a proof. Neither is a
tool name, a row count on its own, or "I checked". If a claim goes into a doc, a
ticket, a PR, a Slack message or a report, the artifact goes with it.

Three shapes cover almost everything:

```
logs     a log-search URL carrying the query, the time range, and the field breakdown
metric   a chart URL carrying the query verbatim, and the same time range
code     a permalink pinned to a SHA or tag, with the line range
```

- Make a logs link render the breakdown the claim rests on, not just the matching rows.
- Paste the alert's or dashboard's own query verbatim into a metric link — a query you
  retyped is a different query.
- Pin code links to an immutable ref and verify the range there; a local checkout lags,
  and line numbers drift.
- URL-encode the query rather than hand-escaping: `jq -rn --arg s "$Q" '$s|@uri'`.
- State the sample size, and say when a result was truncated at a row cap.

Where an environment has its own house formats for these, they live in that
environment's own config, not here. **A claim with no reproducible artifact does not
ship** — cut it, or mark it explicitly as unverified inference.

## 2. Challenge root-cause and impact claims before they ship

Do not publish a root cause or an impact assessment that has only been argued for.
Spawn a subagent whose brief is to **refute** it — never to confirm it. Hand it the
claims verbatim, the specific attacks you can think of, the tooling constraints, and
read-only access. Require a verdict per claim: **SURVIVES / REFUTED / UNTESTABLE**, each
with its own proof link.

- Run challenges for independent claims in parallel.
- A surviving objection becomes an explicit unverified line, not a silent omission.
- A refuted claim is rewritten and the retraction left visible, never quietly dropped.
- This is the standing exception to any "don't use subagents" default.

## 3. Aggregate before you generalise

Never assert a property of a population from one sampled row, file, or test. Aggregate
over the whole result set, say what you aggregated over, and say when the set was
truncated.

**Why these exist:** a single sampled log row once produced a confident, wrong claim
about what a hundred rollbacks were — the reader could not check it, because nothing
said where it came from.
