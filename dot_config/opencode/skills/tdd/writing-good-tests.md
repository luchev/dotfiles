# Writing Good Tests

**Load when:** writing or changing tests, adding mocks, or adding test
helpers and cleanup.

Two rules govern everything below:

```
1. Every test names the break it catches
2. Every test exercises the real thing
```

Strict TDD produces both for free. A test written first and watched failing
against real code has already proven it can fail, and only earns a mock once
the real dependency proves slow or external.

## 1. Name the Break

Before writing the body, answer: **what production change should make this
test fail, and is that change a bug or a decision?** If the only changes that
break it are deliberate ones, the test fires on every redesign and sleeps
through every bug.

**Derive expectations independently.** Literals and hand-checked fixtures;
table-driven cases with literal `want` values are the best shape. An
expectation computed by the code under test passes no matter what that code
does:

```go
// ❌ mirror assertion — same builder on both sides, always true
want := buildQuery(Filter{Tag: "urgent"})
got  := buildQuery(Filter{Tag: "urgent"})

// ✅ hand-derived literal
want := `tag:"urgent"`
```

**No change detectors.** Not `assert(MAX_RETRIES == 5)` — that asserts a
decision. Assert the behavior that depends on it: a failing call is retried
five times and there is no sixth attempt.

**Behavior, not text.** Asserting that a file contains a line proves only
that the source is the source. Run the thing against controlled input and
assert output, side effects, or exit code.

## 2. Exercise the Real Thing

A mock tests the mock. Every mock is a claim that the real component's
behavior does not matter here — usually false.

Mock only what is genuinely slow, external, non-deterministic, or
destructive: network calls, paid APIs, wall-clock time, randomness. Use the
real filesystem in a temp dir, the real parser, the real struct.

When you must fake something, fake it at the edge — one adapter at the
boundary — not throughout the call chain. If a test needs five mocks to run,
the design is too coupled; that is the finding, not the test setup.

## 3. The Mutation Check

The cheapest way to find out whether a test is real: break the code on
purpose and confirm the test fails.

```
flip a condition   → test must fail
delete a side effect → test must fail
return a zero value  → test must fail
```

Still green? The test does not cover what you think it covers. This is the
same red-green discipline as `/tdd`, applied after the fact — use it on any
test you did not watch fail.

## 4. Tests Ship With the Implementation

A test written a week later is a test written against the code, not the
requirement. It reproduces the implementation's assumptions, including the
wrong ones. Same commit, or it is a change detector.

## Warning Signs

| Sign | What it means |
|---|---|
| Test passes on first run, never seen failing | Unproven — mutation-check it |
| Expectation computed by the code under test | Mirror assertion, always true |
| Asserting a constant's value | Change detector |
| Five mocks to reach one assertion | Design too coupled, not a test problem |
| `sleep` in a test | Flake in waiting — wait on the condition, not the clock |
| Huge shared setup | Tests coupled to each other; extract or simplify |
| Test name says "works correctly" | You could not name the break |
