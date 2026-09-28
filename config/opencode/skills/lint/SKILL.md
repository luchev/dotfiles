---
name: lint
description: Check or fix Go coding conventions. Use when the user says "lint", "check conventions", "fix style", "add a convention", or asks to apply/check Go coding practices.
allowedTools:
  - Read
  - Edit
  - Write
  - Bash
  - Glob
  - Grep
---

# /lint — Go Coding Conventions

## Pane status

At the start of any lint run, surface the mode:

```bash
bash ~/.dotfiles/claude/zellij-status.sh status "linting"   # check / check-diff / check-range
bash ~/.dotfiles/claude/zellij-status.sh status "fixing lint"   # fix mode
```

Clear with `status ""` when done.

## Usage

- `/lint check [file or glob]` — report violations, no changes
- `/lint check-diff [base]` — report violations only in lines changed vs `base` (default: `main`)
- `/lint check-range <file>:<start>-<end> [...]` — report violations only in specified line ranges
- `/lint fix [file or glob]` — report then fix; run `bazel build/test` after
- `/lint` — list all conventions
- `/lint add` — record a new convention (describe it next)

**Check mode:** print `<file>:<line>  [Rule]  <description>` per violation, summary at end.
**Fix mode:** same report first, then edit each violation and confirm build/tests pass.

### check-diff mode

Scope lint to only the lines added or modified in the current branch:

```bash
# Get changed Go files
git diff <base>...HEAD --name-only -- '*.go'

# For each file, get the added/changed line numbers
git diff <base>...HEAD -- <file> \
  | grep '^@@' \
  | sed 's/.*+\([0-9]*\),\{0,1\}\([0-9]*\).*/\1 \2/' \
  | awk '{start=$1; len=($2==""?1:$2); for(i=start;i<start+len;i++) print i}'
```

Read each changed file, then check only the lines in those ranges against all conventions. Report violations as `<file>:<line>  [Rule]  <description>` — skip lines outside the changed ranges entirely.

### check-range mode

Scope lint to explicit line ranges in one or more files:

```
/lint check-range internal/foo/bar.go:10-50
/lint check-range internal/foo/bar.go:10-50 internal/foo/baz.go:1-30
```

Parse each argument as `<file>:<start>-<end>`. Read each file, then check only lines `start` through `end` (inclusive) against all conventions. Report violations as `<file>:<line>  [Rule]  <description>` — skip lines outside the specified ranges entirely.

---

## High-signal pattern map

Before scanning the conventions list top-to-bottom, grep the changed lines for these code patterns. Each one maps to a specific rule that is easy to miss. Always run this check first, especially in `*_test.go` files where T-rules are easy to forget.

| Pattern in changed lines | File scope | Rule |
|---|---|---|
| `make(chan struct{})` followed by `close(...)` or `<-...` | `*_test.go` | T6 — use `configtestutil.NewDoneChannel()` + `WaitForDoneChannel(t, ch)` |
| `time.Sleep(` followed by an assertion | `*_test.go` | T8 — use `require.Eventually` |
| `.Do(func(...)` or `mock.EXPECT().*Return(...)` after a `time.Sleep` | `*_test.go` | T7 — signal via `.Do()` closure, not sleep |
| `context.Background()` | `*_test.go` | T9 — use `configtestutil.TestCtx(t)` |
| Generic mock literals (`"a"`, `"foo"`) or single-letter/suffixed vars (`w1`, `mark`, `tmp`) | `*_test.go` | T12 — self-documenting test data |
| `chan ` var named `ch`, `errCh`, `eCh`, or any other than `<subject><What>Ch` | all `.go` | N6 |
| `make(map[...]...)` of any name not in `<Key>To<Value>` form | all `.go` | N7 |
| `panic(` outside `main()` | non-test `.go` | E8 |
| `failed to ` in `fmt.Errorf` or `errors.New` | all `.go` | E7 |
| `context.With*` not immediately followed by `defer cancel()` | all `.go` | C6 |
| `else {` after a return/continue/break in the `if` body | all `.go` | O2 |
| `[]byte("constant")` inside a `for`/`range` loop | all `.go` | P2 |

After this map check, still scan the full convention list for anything not covered above — the map is a backstop, not a substitute.

---

## Conventions

### Naming

**N1.** Receiver: short type abbreviation, consistent, never `self`/`this` — `func (u *User)` not `func (self *User)`
**N2.** Booleans: prefix `Is`, `Has`, `Can` — `IsValid`, `HasPermission`, not `Valid`, `Permission`
**N3.** Acronyms all-caps — `HTTPServer`, `UserID`, `ParseURL` not `HttpServer`, `UserId`
**N4.** No redundancy with package name — `user.ID` not `user.UserID`; `errors.New` not `errors.NewError`
**N5.** Single-method interfaces: name after method + `-er`, no `I` prefix — `io.Reader` not `IReader`
**N6.** Channel variables: `<subject><What>Ch` — never bare `ch`, `eCh`, `errCh`; e.g. `registerErrCh`, `snapshotReadyCh`
**N7.** Maps: `<Key>To<Value>` — `environmentToDeployerPort` not `ports` or `mapping`
**N8.** Unexported package-level vars/consts: prefix `_` — `var _defaultTimeout`. Exception: error vars use `err` prefix (E4). Local (function-scoped) constants do NOT get `_`.
**N9.** No generic package names — `util`, `common`, `lib`, `shared`, `misc`, `helpers` are banned.
**N10.** Don't shadow Go built-in identifiers (`error`, `string`, `len`, `cap`, `make`, `new`, `close`) as var/param/field names — use `errorMessage`, `msg`, `err`, `str` instead.
**N11.** Printf-style variadic functions must end with `f` so `go vet` can analyze format strings — `Wrapf` not `Wrap`.

---

### Functions

**F1.** `context.Context` is always the first parameter when the function performs I/O, calls downstream services, or needs cancellation/tracing. Exception: pure sink/callback methods (e.g., observation reporters, event handlers that receive a pre-configured logger) may omit context when they have no downstream calls to propagate it to.
**F2.** `error` is always the last return value
**F3.** Max ~4 parameters; beyond that use a struct — `func Create(p CreateParams)` not `func Create(name, region, env, tier, owner string)`
**F4.** Avoid named return values except for disambiguation in very short functions
**F5.** Don't mutate input arguments — copy if modification is needed
**F6.** Comment unnamed bool literals at call sites — `process(data, true /* overwrite */)` not `process(data, true)`
**F7.** Functions do one thing only and stay short — target ≤15 lines, hard limit ~30 lines. If a function needs a comment to explain what the next block does, that block should be its own function. Exception: functions that are purely a sequence of steps with no branching (e.g., a `setup()` that wires components together) may be longer if each line is simple.

---

### Variables

**V1.** Declare variables close to first use; minimize scope
**V2.** Use `var s []string` (nil) not `s := []string{}` when the slice may stay empty
**V3.** Short names only in short scopes (`i`, `n` in loops); full names elsewhere
**V4.** No magic numbers — name constants at narrowest scope: use a `const`/`var` inside the function if it's single-use there, or package-level (with `_` prefix per N8) if used in 2+ functions. Exception: values derived from another constant can be inlined (`n+1` using existing `n`). Exception: byte-size thresholds are acceptable without named constants when the bucket label on the immediately following line makes the unit and magnitude unambiguous (e.g., `if bytes <= 50000 { return "50kB" }`).
**V5.** Use init-statements when the variable is only used inside the block — `if err := f(); err != nil { return err }` not `err := f(); if err != nil { return err }`
**V6.** Don't force variables into init-statements when needed outside (exception to V5) — `data, err := os.ReadFile(name); if err != nil { return err }` not `if data, err := ...; err == nil { ... }`
**V7.** At package level, omit the type when implied — `var _s = F()` not `var _s string = F()`. Specify type only when they differ (e.g. `var _e error = F()` when F returns `*MyError`).
**V8.** Return `nil` for empty slices, not `[]T{}` — `return nil` not `return []string{}`
**V9.** Check slice emptiness with `len(s) == 0`, not `s == nil`
**V10.** Use `make(map[K]V)` for dynamic maps; map literals for fixed elements. Provide capacity hint: `make(map[K]V, len(keys))`

---

### Errors

**E1.** Always wrap with context and `%w` — `return fmt.Errorf("fetching user %s: %w", id, err)` not `return err`
**E2.** Use `%w` not `%v` — `%v` turns the error into a string, breaking `errors.Is`/`errors.As`
**E3.** Handle errors once — log OR return, never both (causes duplicate log lines)
**E4.** Naming: exported vars `ErrFoo`, unexported `errFoo`, custom types `FooError`
**E5.** Match errors with `errors.Is`/`errors.As` — never string comparison
**E6.** Don't discard errors with `_` unless intentional and documented
**E7.** Error context must not start with "failed to" — it stacks redundantly. Use `"open store: %w"` not `"failed to open store: %w"`
**E8.** Never `panic` in production — return `error`. In tests use `t.Fatal`/`t.FailNow` not `panic`.
**E9.** `defer resource.Close()` must not silently drop the error — capture it into a named return or use a `safeClose` helper: `defer func() { if cerr := r.Close(); cerr != nil && err == nil { err = cerr } }()`. Plain `defer r.Close()` is only acceptable when the caller genuinely doesn't care about close errors (e.g., read-only resources).
**EH1.** Export `IsXxxErr(err error) bool` helpers alongside custom types — `func IsNotFoundErr(err error) bool { var e *NotFoundError; return errors.As(err, &e) }`. Callers must not type-assert directly.

---

### Interfaces & Types

**I1.** Accept interfaces, return concrete types
**I2.** Define interfaces in the consumer package, not the producer
**I3.** Keep interfaces small; compose small interfaces rather than one large one
**I4.** Compile-time check for exported types — `var _ MyInterface = (*MyImpl)(nil)`
**I5.** Type assertions: always comma-ok — `val, ok := i.(string)` never `val := i.(string)` (panics)
**I6.** Zero value of a type should be usable without initialization where possible
**I7.** Don't embed types in exported structs — leaks implementation details. Use a named field + delegate methods: `type ConcreteList struct { list *AbstractList }` not `struct { *AbstractList }`
**I8.** Embedded types must be at the TOP of the struct field list, with an empty line before regular fields.

---

### Concurrency

**C1.** Channels: size 0 or 1 only — other sizes require justification
**C2.** Protect shared state with `sync.Mutex`; use channels for coordination/signaling. Never embed `sync.Mutex` — use named field `mu sync.Mutex` (embedding exposes Lock/Unlock as public API).
**C3.** Every goroutine must have a defined exit condition; document ownership
**C4.** Never start a goroutine in `init()`
**C5.** Use `go.uber.org/atomic` typed wrappers instead of raw `sync/atomic` on primitive types — `atomic.Bool` not `int32` (raw reads without atomic ops are a data race)
**C6.** `context.With*` calls must be immediately followed by `defer cancel()` on the next line — never separate them with other code. `ctx, cancel := context.WithTimeout(p, d); defer cancel()` not `ctx, cancel := ...; doSomething(); defer cancel()`
**C7.** When a function requires the caller to hold a specific mutex, accept a `tokenlock.Token[T]` parameter instead of documenting the requirement in a comment. Use a `tokenlock.Locker[T]` helper from your repo, where `T` is a phantom type unique to the lock — `LockAndCreateToken()` returns a `Token[T]` that proves at compile time the caller acquired that specific lock, and `Token[T]` can only be constructed inside the `tokenlock` package. Pattern:
```go
type fooLockKey struct{}              // phantom type identifies the lock
type Foo struct {
    lock tokenlock.Locker[fooLockKey] // typed mutex
    data map[string]int
}

// requires caller to hold f.lock — enforced by the type system
func (f *Foo) mutateLocked(_ tokenlock.Token[fooLockKey], k string, v int) {
    f.data[k] = v
}

func (f *Foo) Set(k string, v int) {
    tok := f.lock.LockAndCreateToken()
    defer f.lock.UnlockTokenLock(tok)
    f.mutateLocked(tok, k, v)
}
```
Use this when a `*Locked` helper would otherwise need a `// caller must hold f.mu` comment, or when multiple methods share lock-protected logic. One phantom type per distinct lock — never reuse `fooLockKey` for an unrelated mutex.

---

### Code Organization

**O1.** File declaration order: `const` → type definitions → `var` → exported data structs → interface → implementing struct → `New` → exported methods → unexported methods
**O2.** Return early — no `else` after a guard clause; keep nesting ≤ 1 level — `if !ok { doB(); return }; doA()` not `if ok { doA() } else { doB() }`
**O2a.** When a variable is set in both branches, use default-then-override — `a := 10; if b { a = 100 }` not `if b { a = 100 } else { a = 10 }`
**O3.** Export only what external packages need
**O4.** Avoid `init()` — prefer explicit initialization in `main` or constructors
**O5.** Use `defer` for cleanup (close, unlock, cancel) — always, not conditionally
**O6.** Use canonical serializers — `labels.ToContextTags(lbls)` not `[]string{"label:env_type\x01test"}`. Hardcoded formats bypass validation and break if encoding changes.
**O7.** Copy slices/maps at package boundaries — retaining a reference to caller-owned data allows silent external mutation
**O8.** Avoid mutable global variables — prefer dependency injection. Don't mutate package-level `var`s after initialization.
**O9.** Only call `os.Exit` or `log.Fatal*` in `main()`. All other functions return `error`.
**O10.** Group related `const`/`var`/`type`/`import` in blocks; split unrelated items into separate groups.
**O11.** Two import groups only: stdlib first, everything else second. (goimports enforces this.)
**O12.** In loops, use `continue` to guard early — `if v.F1 != 1 { continue }; process(v)` not `if v.F1 == 1 { process(v) } else { ... }`
**O13.** Don't reimplement slice membership — use `slices.Contains(list, target)` (stdlib). Flag any local `InSlice`, `contains`, or inline `for`-loop-with-equality-check that just returns a bool.
**O14.** Don't reimplement sorted map keys — use `slices.Sorted(maps.Keys(m))` (Go 1.23+ stdlib). Flag local `sortedKeys` helpers or manual `append`+`sort.Strings` patterns.

---

### Observability

**OBS1.** Use Histograms, not Timers (Timers aggregate inaccurately for P99)
**OBS2.** Hardcode metric names at emission site; use `const` only if emitted in 2+ places; no dynamic construction (breaks `grep`)
**OBS3.** Keep metric tag cardinality under 10K distinct combinations
**OBS4.** Always call `logger.With(zapfx.Context(ctx))` to attach trace IDs
**OBS5.** Use `_` as word separator in log tag names — `object_type` not `objectType`
**OBS6.** Extract log tag helpers when a tag appears in 2+ files
**OBS7.** Truncate log messages that may exceed ~1KB (pipeline silently drops oversized entries)
**OBS8.** Use `logger.Named("component-name")` when storing a logger on a struct (kebab-case, matches package name)
**OBS9.** Use project-defined constants for log tag names — `zap.String(consts.LogObjectType, t)` not `zap.String("object_type", t)`
**OBS10.** Defer histogram recording to capture all return paths: `defer func() { g.scope.Histogram("fetch.latency", _buckets).RecordDuration(time.Since(start)) }()`
**OBS11.** Emit metrics using the full metric name at the call site — do not use `SubScope` to invisibly prepend prefixes. Use `scope.Counter("service.convergence.count")` not `scope.SubScope("service").Counter("convergence.count")`. The full name must be visible at the emission site so it is greppable.
**OBS12.** Omit log fields whose value may be empty — emit `zap.Skip()` for empty strings/IDs rather than logging an empty tag. Extract a helper when the same field appears in 2+ places: `func objectIDField(id string) zap.Field { if id == "" { return zap.Skip() }; return zap.String("object_id", id) }`
**OBS13.** Each distinct semantic ID/name field that may be empty gets its own named `zap.Field` helper — `patchIDField`, `objectIDField`, `namespaceField`, etc. Do not inline the `if id == "" { return zap.Skip() }` check at every log site; one helper per field type used in 2+ log calls.
**OBS14.** Use `config/shared/metrics/helpers.go` wrappers (`RecordHistogramWithStatus`, `RecordHistogramWithObjectType`, `RecordHistogramWithStatusAndType`) instead of manually composing `scope.Tagged(...).Histogram(...)`. The helpers standardize status-code extraction and object-type tagging so those tags are consistent across all services.

---

### Testing

**T1.** Match structure to complexity: single case → plain test; many similar cases → table (`tests` slice, `tt` var); many different setups → separate `t.Run` subtests
**T2.** No change-detector tests — test behavior, not implementation
**T3.** Test case struct name field is always `name` or `msg` — never `testName`, `description`, `scenario`
**T4.** Table test inputs use `give` prefix, expected outputs use `want` prefix — `{give: "foo", want: "bar"}` not `{input: "foo", expected: "bar"}`
**T5.** No conditional logic inside a table test loop body (`if tt.shouldCallX`, mock branching) — split complex scenarios into separate `Test...` functions.
**T6.** Channel-based test synchronization: use `configtestutil.NewDoneChannel()` + `WaitForDoneChannel(t, ch)` — never a bare `make(chan struct{})` with `close()` in test code, even when there is no explicit timeout. The helper uses `sync.OnceFunc` to prevent double-close panics and enforces a 20s timeout with a failing assertion on expiry. **Detection:** in any `*_test.go` file, flag every `make(chan struct{})` whose channel is later closed (`close(ch)`) or received from (`<-ch`) as a signalling primitive — replace with `NewDoneChannel()`. Applies whether or not the test has manual `select`/timeout logic; the bare close-and-receive pattern alone is the violation.
**T7.** Signal async mock completion via `.Do()` closure, not `time.Sleep()` — `mock.EXPECT().Method(gomock.Any()).Do(func(...) { signalDone() }).Return(nil)`. The closure fires when the production code calls the mock, making the test deterministic.
**T8.** Use `require.Eventually(t, condition, timeout, interval)` for polling async state — never `time.Sleep()` followed by a single assertion. `time.Sleep` is a fixed delay that is either too short (flaky) or too long (slow).
**T9.** Test contexts: use `configtestutil.TestCtx(t)` (20s timeout, cleaned up via `t.Cleanup`) — never `context.Background()` in a test. A test that hangs forever makes CI unusable; the 20s cap surfaces the hang as a failing assertion rather than a timeout-killed job.
**T10.** Every package whose `TestMain` starts goroutines must call `goleak.VerifyTestMain(m, ...)` to detect leaks — place it in a `TestMain` in a `*_leak_test.go` file. Known-safe background goroutines (opencensus worker, etc.) go in the ignore list with a comment explaining why.
**T11.** FX module tests use `fxtest.New(t, Module, fx.Supply(...), fx.Populate(&out)).RequireStart().RequireStop()` — never manually wire constructors that the module already wires. This tests the actual DI graph, not a hand-rolled approximation of it.
**T12.** Test data must be self-documenting — mock argument literals, map keys, and local variable names describe intent, not placeholders. Use `"distributor-host-1"`, `firstNewType := "first-new-object-type"`, `typeThatMustNotBeSubscribed`, `markSubscribed`/`pendingSubscribeCalls` — never `"a"`, `"b"`, `"h1"`, `w1`, `mark`, `remaining`. Applies to string literals AND identifier names. **Detection:** flag single-letter/number-suffixed mock vars (`w1`, `w2`), generic string literals passed to mocks (`"a"`, `"foo"`, `"type1"`), and counters/closures named `mark`/`tmp`/`remaining` in `*_test.go`.

---

### Fx

**FX1.** Every package exposes a `Module` var — `var Module = fx.Options(fx.Provide(New))`
**FX2.** Constructors use `Params`/`Result` structs:
```go
type Params struct { fx.In; Logger *zap.Logger; Config Config }
type Result struct { fx.Out; Gateway Gateway }
func New(p Params) (Result, error) { ... }
```
**FX3.** Config structs embed `cfgparse.Struct` with snake_case YAML tags:
```go
type Config struct {
  cfgparse.Struct `yaml:",inline" config:"my-service"`
  BaseURL string  `yaml:"base_url"`
}
```
**CON1.** Always validate config at top of `New()` — `if err := p.Config.Validate(); err != nil { return ..., fmt.Errorf("invalid config: %w", err) }`

---

### Enums

**EN1.** Last constant is `_<TypeName>Max` (unexported sentinel) for range validation — `s > StatusInvalid && s < _statusMax`
**EN2.** String conversion uses a package-level lookup map, never a switch (switch silently compiles with missing cases) — `var _statusNames = map[Status]string{...}; func (s Status) String() string { if n, ok := _statusNames[s]; ok { return n }; return "unknown" }`
**EN3.** Expose both `String()` and `ParseXxx(s string) (Type, error)` for every enum
**EN4.** Use `iota` starting at 1 for enums; 0 is the "unset/invalid" zero value
**EN5.** `ParseXxx` string-to-enum functions must return the `_Invalid` zero value (not a default) for unknown inputs — `if v, ok := _enumByName[s]; ok { return v, nil }; return EnumInvalid, fmt.Errorf("unknown value: %s", s)`. Silently mapping unknown strings to a valid variant hides bugs.
**EN6.** Proto enum string converters shared between more than one service must live in the IDL-adjacent shared package — never duplicate them per service. A converter defined twice will diverge silently.

---

### Style

**S1.** All marshaled struct fields (JSON, YAML, etc.) must have explicit struct tags — `Price int \`json:"price"\`` not `Price int`
**S2.** Soft 99-character line length limit.
**S3.** Use raw string literals for strings with quotes, backslashes, or regex — `` `\d+\.\d+` `` not `"\\d+\\.\\d+"`
**S4.** Always use field names in struct literals — `User{FirstName: "John"}` not `User{"John"}`
**S5.** Omit zero-value fields from struct literals — `User{FirstName: "John"}` not `User{FirstName: "John", Admin: false}`
**S6.** Use `var T` not `T{}` for all-zero-value structs — `var user User` not `user := User{}`
**S7.** Use `&T{...}` not `new(T)` for struct pointer initialization — `&T{Name: "bar"}` not `new(T)` then field assignment
**S8.** Printf format strings declared outside the call must be `const` — `const msg = "..."` not `msg := "..."` (`go vet` can't analyze vars)

---

### Performance

**P1.** In hot paths, prefer `strconv` over `fmt` for number-to-string — `strconv.Itoa(n)` not `fmt.Sprint(n)`
**P2.** Don't convert a fixed string to `[]byte` inside a loop — convert once before: `data := []byte("Hello"); for { w.Write(data) }`
**P3.** Specify capacity when creating slices/maps with a known size — `make([]T, 0, n)` and `make(map[K]V, n)`

---

### Time

**TM1.** When forced to store duration/timestamp as a non-`time.Duration`/`time.Time` type, include the unit in the name — `IntervalMillis int` not `Interval int`
**TM2.** Use `time.Time` for timestamps and `time.Duration` for intervals — never strings or numeric epochs in struct fields, function params, or APIs unless required by an external protocol.
**TM3.** Store timestamps in UTC; convert to local only at display boundaries — `t.UTC()` on persistence, `t.In(loc)` on render. Never `time.Now()` without an explicit zone if the value crosses a boundary.

---

### Protobuf

**PB1.** Service names end with `Service` — `service UserService { ... }` not `service User { ... }`.
**PB2.** RPC request/response messages match the RPC name with `Request`/`Response` suffix — `rpc GetUser(GetUserRequest) returns (GetUserResponse);` never reuse a generic `Empty` or share message types across unrelated RPCs.
**PB3.** Enum values are prefixed with the enum type name and start with sentinels: `0 = <NAME>_INVALID`, `1 = <NAME>_UNSET`, then real values — `enum Status { STATUS_INVALID = 0; STATUS_UNSET = 1; STATUS_ACTIVE = 2; }`.

---

### Comments

**CM1.** No `TODO`/`FIXME`/`XXX` comments without an associated tracking ticket — `// TODO(PROJ-1234): handle retries` not `// TODO: handle retries`. Untracked TODOs accumulate and become permanent.
