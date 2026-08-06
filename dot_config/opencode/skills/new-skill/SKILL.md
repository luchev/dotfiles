---
name: new-skill
description: Scaffold a new OpenCode skill following established conventions. Creates ~/.config/opencode/skills/<name>/SKILL.md with correct frontmatter, allowedTools, argument parsing, and step structure. Use when adding a skill.
allowedTools:
  - Bash(test *)
  - Bash(mkdir *)
  - Read
  - Write
  - AskUserQuestion
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
allowedTools:
  - <tools>
---
```

**Validate before writing:**

| Field | Rule |
|---|---|
| `name` | kebab-case, `^[a-z0-9]+(-[a-z0-9]+)*$`, matches directory name |
| `description` | ≤ 1024 chars, no angle brackets |
| keys | only `name`, `description`, `allowedTools`, `license`, `metadata` |

**Write descriptions pushy.** Claude undertriggers skills — a neutral description means
the skill never loads. State the trigger phrases verbatim and instruct activation:
"Use this whenever the user mentions X, even if they don't explicitly ask for it."

- Weak: `Formats Go test tables.`
- Strong: `Formats Go test tables. Use whenever the user says "table test", "fix this test", or edits a _test.go file with a tests slice, even if they don't ask for formatting.`

**allowedTools** (include only what's used):

| Capability | Entry |
|---|---|
| Git | `Bash(git *)` |
| mkdir | `Bash(mkdir *)` |
| Specific cmds | `Bash(gh *)`, `Bash(npm *)`, `Bash(cargo *)`, etc. |
| File ops | `Read`, `Write`, `Edit`, `Glob`, `Grep` |
| Delegation | `Agent`, `Skill` |
| Task tracking | `TaskCreate`, `TaskUpdate`, `TaskList` |
| Interactive | `AskUserQuestion` |
| MCP | `mcp__<server>__<tool>`, etc. |

Omit `allowedTools` entirely if the skill uses only always-available tools and the list adds noise.

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
