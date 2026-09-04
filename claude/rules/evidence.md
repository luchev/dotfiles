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

At Uber the three shapes are:

```
logs    https://umonitor.uberinternal.com/services/<svc>/logs?q=<urlencoded lucene>&from=<ISO .000Z>&until=<ISO .000Z>
metric  https://umonitor.uberinternal.com/query?from=<ISO>&q=<urlencoded M3QL>&sources=m3&until=<ISO>
code    https://sg.uberinternal.com/r/code.uber.internal/uber-code/go-code/-/blob/<path>?L<start>-<end>
```

- Add `| @table:<field>` to a logs link so it renders the breakdown the claim rests on.
- Paste the alert's or dashboard's own query verbatim into a metric link.
- Verify a code range at HEAD before citing it; a local checkout lags.
- Encode with `jq -rn --arg s "$Q" '$s|@uri'`.
- State the sample size, and say when a result was truncated at a row cap.

Elsewhere the same rule holds in the local idiom: a permalink at a pinned SHA, a build
URL, a dashboard link, a command with its output. **A claim with no reproducible
artifact does not ship** — cut it, or mark it explicitly as unverified inference.

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
