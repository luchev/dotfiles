---
name: lint-go
description: Check or fix Go coding conventions. Use when the user says "lint", "check conventions", "fix style", "add a convention", or asks to apply/check Go coding practices.
---

# /lint-go — Go Coding Conventions

## Usage

- `/lint-go check [file or glob]` — report violations, no changes
- `/lint-go fix [file or glob]` — report then fix; run tests after
- `/lint-go` — list all conventions
- `/lint-go add` — record a new convention (describe it next)

**Check mode:** print `<file>:<line>  [Rule]  <description>` per violation, summary at end.
**Fix mode:** same report first, then edit each violation and confirm tests pass.

---

## Conventions

### Naming

**N1.** Receiver: short type abbreviation, consistent, never `self`/`this` — `func (u *User)` not `func (self *User)`
**N2.** Booleans: prefix `Is`, `Has`, `Can` — `IsValid`, `HasPermission`, not `Valid`, `Permission`
**N3.** Acronyms all-caps — `HTTPServer`, `UserID`, `ParseURL` not `HttpServer`, `UserId`
**N4.** No redundancy with package name — `user.ID` not `user.UserID`; `errors.New` not `errors.NewError`
**N5.** Single-method interfaces: name after method + `-er`, no `I` prefix — `io.Reader` not `IReader`
**N6.** Channel variables: `<subject><What>Ch` — never bare `ch`, `eCh`, `errCh`; e.g. `registerErrCh`, `snapshotReadyCh`
**N7.** Maps: `<Key>To<Value>` — `environmentToPort` not `ports` or `mapping`
**N8.** Unexported package-level vars/consts: prefix `_` — `var _defaultTimeout`. Exception: error vars use `err` prefix (E4). Local (function-scoped) constants do NOT get `_`.
**N9.** No generic package names — `util`, `common`, `lib`, `shared`, `misc`, `helpers` are banned.
**N10.** Don't shadow Go built-in identifiers (`error`, `string`, `len`, `cap`, `make`, `new`, `close`) as var/param/field names — use `errorMessage`, `msg`, `err`, `str` instead.
**N11.** Printf-style variadic functions must end with `f` so `go vet` can analyze format strings — `Wrapf` not `Wrap`.

---

### Functions

**F1.** `context.Context` is always the first parameter
**F2.** `error` is always the last return value
**F3.** Max ~4 parameters; beyond that use a struct — `func Create(p CreateParams)` not `func Create(name, region, env, tier, owner string)`
**F4.** Avoid named return values except for disambiguation in very short functions
**F5.** Don't mutate input arguments — copy if modification is needed
**F6.** Comment unnamed bool literals at call sites — `process(data, true /* overwrite */)` not `process(data, true)`

---

### Variables

**V1.** Declare variables close to first use; minimize scope
**V2.** Use `var s []string` (nil) not `s := []string{}` when the slice may stay empty
**V3.** Short names only in short scopes (`i`, `n` in loops); full names elsewhere
**V4.** No magic numbers — name constants at narrowest scope (inside func if single-use, package-level if multi-func). Exception: values derived from another constant can be inlined (`n+1` using existing `n`).
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
**C5.** Use typed atomic wrappers from `sync/atomic` (e.g. `atomic.Bool`, `atomic.Int64`) instead of raw `int32` with manual `atomic.Load`/`atomic.Store` calls — raw reads without atomic ops are a data race

---

### Code Organization

**O1.** File declaration order: `const` → type definitions → `var` → exported data structs → interface → implementing struct → `New` → exported methods → unexported methods
**O2.** Return early — no `else` after a guard clause; keep nesting ≤ 1 level — `if !ok { doB(); return }; doA()` not `if ok { doA() } else { doB() }`
**O2a.** When a variable is set in both branches, use default-then-override — `a := 10; if b { a = 100 }` not `if b { a = 100 } else { a = 10 }`
**O3.** Export only what external packages need
**O4.** Avoid `init()` — prefer explicit initialization in `main` or constructors
**O5.** Use `defer` for cleanup (close, unlock, cancel) — always, not conditionally
**O6.** Use project-defined serialization helpers for structured data — avoid hardcoding wire formats as string literals. Hardcoded formats bypass validation and break if encoding changes.
**O7.** Copy slices/maps at package boundaries — retaining a reference to caller-owned data allows silent external mutation
**O8.** Avoid mutable global variables — prefer dependency injection. Don't mutate package-level `var`s after initialization.
**O9.** Only call `os.Exit` or `log.Fatal*` in `main()`. All other functions return `error`.
**O10.** Group related `const`/`var`/`type`/`import` in blocks; split unrelated items into separate groups.
**O11.** Two import groups only: stdlib first, everything else second. (goimports enforces this.)
**O12.** In loops, use `continue` to guard early — `if v.F1 != 1 { continue }; process(v)` not `if v.F1 == 1 { process(v) } else { ... }`

---

### Observability

**OBS1.** Use Histograms, not Timers (Timers aggregate inaccurately for P99)
**OBS2.** Hardcode metric names at emission site; use `const` only if emitted in 2+ places; no dynamic construction (breaks `grep`)
**OBS3.** Keep metric tag cardinality under 10K distinct combinations
**OBS4.** Always attach request context to loggers to propagate trace/request IDs
**OBS5.** Use `_` as word separator in log tag names — `object_type` not `objectType`
**OBS6.** Extract log tag helpers when a tag appears in 2+ files
**OBS7.** Truncate log messages that may exceed ~1KB (pipeline silently drops oversized entries)
**OBS8.** Use `logger.Named("component-name")` when storing a logger on a struct (kebab-case, matches package name)
**OBS9.** Use project-defined constants for log tag names rather than inline string literals

---

### Testing

**T1.** Match structure to complexity: single case → plain test; many similar cases → table (`tests` slice, `tt` var); many different setups → separate `t.Run` subtests
**T2.** No change-detector tests — test behavior, not implementation
**T3.** Test case struct name field is always `name` or `msg` — never `testName`, `description`, `scenario`
**T4.** Table test inputs use `give` prefix, expected outputs use `want` prefix — `{give: "foo", want: "bar"}` not `{input: "foo", expected: "bar"}`
**T5.** No conditional logic inside a table test loop body (`if tt.shouldCallX`, mock branching) — split complex scenarios into separate `Test...` functions.

---

### Enums

**EN1.** Last constant is `_<TypeName>Max` (unexported sentinel) for range validation — `s > StatusInvalid && s < _statusMax`
**EN2.** String conversion uses a package-level lookup map, never a switch (switch silently compiles with missing cases) — `var _statusNames = map[Status]string{...}; func (s Status) String() string { if n, ok := _statusNames[s]; ok { return n }; return "unknown" }`
**EN3.** Expose both `String()` and `ParseXxx(s string) (Type, error)` for every enum
**EN4.** Use `iota` starting at 1 for enums; 0 is the "unset/invalid" zero value

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
