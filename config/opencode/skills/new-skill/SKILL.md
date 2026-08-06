---
name: new-skill
description: Scaffold a new OpenCode skill following established conventions. Creates a SKILL.md under ~/.config/opencode/skills/ with correct frontmatter, allowed-tools, argument parsing, and step structure. Use when adding a skill.
allowed-tools: Bash(test:*), Bash(mkdir:*), Read, Write, AskUserQuestion
---

# /new-skill — Scaffold a New Skill

## Argument Parsing

- `my-skill` — name only
- `my-skill Do X when Y` — name + description

`NAME` = first word (lowercase, hyphens). `DESCRIPTION` = remainder.

## Step 1: Gather intent

If `DESCRIPTION` empty: ask for one-sentence description of what it does and when it triggers.

Ask (`AskUserQuestion`, batch): (1) Takes arguments? (2) How many steps/phases? (3) Which tools needed?

## Step 2: Check for conflicts

```bash
test -d ~/.config/opencode/skills/$NAME
```

If exists: read current SKILL.md and ask to overwrite. Stop if declined.

## Step 3: Write the skill

```bash
mkdir -p ~/.config/opencode/skills/$NAME
```

Write `~/.config/opencode/skills/$NAME/SKILL.md`:

### Frontmatter

```yaml
---
name: $NAME
description: $DESCRIPTION
allowed-tools: <comma-separated tools>
---
```

**Validate before writing:**

| Field | Rule |
|---|---|
| `name` | kebab-case, `^[a-z0-9]+(-[a-z0-9]+)*$`, ≤ 64 chars, no leading/trailing/doubled hyphen, matches directory name |
| `description` | 1–1024 chars, no angle brackets |
| `compatibility` | optional, ≤ 500 chars — only when the skill needs specific tools or an environment |
| keys | only `name`, `description`, `allowed-tools`, `license`, `compatibility`, `metadata` |

The key is `allowed-tools` — hyphenated, and its value is one string, not a YAML
list. `allowedTools` is silently dropped, leaving the skill with no declared
permissions at all. Validate with `skill-creator/scripts/quick_validate.py` from
[anthropics/skills](https://github.com/anthropics/skills), or against the spec at
<https://agentskills.io/specification>.

**Write descriptions pushy.** Claude undertriggers skills — a neutral description means
the skill never loads. State the trigger phrases verbatim and instruct activation:
"Use this whenever the user mentions X, even if they don't explicitly ask for it."

- Weak: `Formats Go test tables.`
- Strong: `Formats Go test tables. Use whenever the user says "table test", "fix this test", or edits a _test.go file with a tests slice, even if they don't ask for formatting.`

**allowed-tools** (include only what's used) — comma-separated on one line.
Bash entries use a command *prefix* followed by `:*`, not a glob:

| Capability | Entry |
|---|---|
| Git | `Bash(git:*)` |
| A narrower git verb | `Bash(git log:*)` |
| mkdir | `Bash(mkdir:*)` |
| Specific cmds | `Bash(gh:*)`, `Bash(npm:*)`, `Bash(cargo:*)` |
| One exact command | `Bash(ls ~/.config/opencode/sessions/)` |
| File ops | `Read`, `Write`, `Edit`, `Glob`, `Grep` |
| Delegation | `Agent`, `Skill` |
| Task tracking | `TaskCreate`, `TaskUpdate`, `TaskList` |
| Interactive | `AskUserQuestion` |
| MCP | `mcp__<server>__<tool>` |

```yaml
allowed-tools: Bash(git:*), Bash(gh:*), Read, Write
```

Omit `allowed-tools` entirely if the skill uses only always-available tools and the list adds noise.

### Body structure

```markdown
# /$NAME — Title

## Argument Parsing          ← only if skill takes $ARGUMENTS

`$ARGUMENTS` is one of:
- `value` — meaning

Parse: `VAR` = extraction rule

---

## Step 1: Title

Commands and logic.

## Step N: Report

​```
Done.
  Key: value
​```
```

### Conventions

**Voice:** body is imperative/infinitive — "Parse the frontmatter", never "You should parse".
Frontmatter `description` is third-person — "Use when the user says…", describing the skill
from outside.

**Size:** SKILL.md body under 500 lines. Past that, move detail into `references/<topic>.md`
and link it — the body is always loaded, references are read on demand. Any reference file
over 300 lines gets a table of contents at the top.

**Domain variants:** one SKILL.md holding workflow + variant selection, one
`references/<variant>.md` per domain (`aws.md`, `gcp.md`). Avoids loading all variants
to use one.

**Lead with the loaded word.** One precise term the model already understands beats a
sentence explaining it. Write "idempotent", not "running it twice leaves the same
result as running it once". Write "the frontier", then define it once. The explanation
costs tokens on every load; the term costs one lookup.

**Delete no-op sentences.** After each line, ask what the model would do differently
without it. "Be careful here", "this is important", "make sure to think about the
consequences" change nothing — they read as instruction and act as filler. A rule
either names an action, a threshold, or a prohibition with teeth, or it goes.

**Steps:** sequential (`Step 1, 2, 3`). Two modes: prefix `S1/A1`. Phases: `R1` (Research), `P1` (Plan), `I1` (Implement).

**Arguments:** received as `$ARGUMENTS`. Parse into named vars. `AskUserQuestion` when required info missing.

**Commands:** always show exact bash in code block. Use `$VARIABLE` placeholders. Explicit decision branches.

**Stop conditions:** `**Stop here.** <reason>` when blocking further progress.

**Guardrails:** read before editing; check preconditions before destructive steps; never `git add -A`.

## Step 4: Report

```
Created ~/.config/opencode/skills/$NAME/SKILL.md

Invoke with:  /$NAME [args]
```
