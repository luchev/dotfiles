# Root Cause Tracing

**Load when:** the error surfaces deep in a call chain, the stack trace is
long, or it is unclear where a bad value came from.

A bug shows up where the bad value is *used*, not where it was *produced*.
Fixing at the point of the error is fixing a symptom. Trace backward to the
original trigger and fix there.

## The Trace

1. **Observe the symptom** — exact error, exact location.
2. **Find the immediate cause** — what line directly produces it?
3. **Ask what called this** — and with what arguments?
4. **Keep going up** — at each frame, is the value already wrong here? If yes,
   this is not the source; go up again.
5. **Stop at the first frame where the value was correct.** The bug is in the
   transition out of that frame.

Worked example: `git init` ran in the source tree, not the temp dir.

```
git init with cwd=''          ← empty cwd resolves to process.cwd()
  ← WorktreeManager.create(projectDir)   projectDir = ''
    ← Session.initializeWorkspace()      passed through
      ← Session.create()                 passed through
        ← test: Project.create(name, ctx.tempDir)
          ← setupCoreTest() returns { tempDir: '' } until beforeEach runs
```

Root cause: a field read before its initializer ran. Fixed by making `tempDir`
a getter that throws when accessed early — not by defaulting the `cwd`.

## When You Cannot Trace by Reading

Instrument *before* the dangerous operation, not after it fails:

```typescript
async function gitInit(directory: string) {
  console.error('DEBUG git init:', {
    directory,
    cwd: process.cwd(),
    stack: new Error().stack,
  });
  await execFileAsync('git', ['init'], { cwd: directory });
}
```

- `console.error`, not the logger — loggers are often suppressed under test.
- Capture `new Error().stack` for the full chain.
- Include the surrounding context: cwd, relevant env vars, the argument itself.
- Filter the run: `npm test 2>&1 | grep 'DEBUG git init'`.

## Finding Which Test Pollutes

When state appears during a suite but no single test is obviously responsible,
bisect: run tests one at a time against a clean tree, checking for the
artifact after each, and stop at the first that creates it.

## Then Add Defense in Depth

Once you know the source, one fix at the source is correct but fragile — a
different code path, a refactor, or a mock can bypass it. Add a check at each
layer the bad value passed through:

| Layer | Purpose | Example |
|---|---|---|
| Entry point | Reject invalid input at the API boundary | `if (!dir) throw` on the public constructor |
| Business logic | Reject what makes no sense for this operation | workspace init requires a non-empty dir |
| Environment guard | Refuse dangerous operations in the wrong context | under test, refuse `git init` outside tmpdir |
| Instrumentation | Leave forensics for the next failure | log dir + stack before the operation |

Each layer catches what the others miss: different call paths skip entry
validation, mocks skip business logic, platform differences need the
environment guard. One validation says "we fixed the bug"; four say "the bug
is now structurally impossible".
