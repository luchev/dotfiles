---
name: new-skill
description: Scaffold a new Gemini CLI skill following established conventions. Creates ~/.gemini/skills/<name>/SKILL.md with correct frontmatter and step structure. Use when adding a skill.
---

# /new-skill — Scaffold a New Skill

## Argument Parsing

- `my-skill` — name only
- `my-skill Do X when Y` — name + description

`NAME` = first word (lowercase, hyphens). `DESCRIPTION` = remainder.

## Step 1: Gather intent

If `DESCRIPTION` empty: ask for a one-sentence description of what it does and when it triggers.

Ask (batch): (1) Takes arguments? (2) How many steps/phases? (3) Any shell commands needed?

## Step 2: Check for conflicts

```bash
test -d ~/.gemini/skills/$NAME
```

If exists: read current SKILL.md and ask to overwrite. Stop if declined.

## Step 3: Write the skill

```bash
mkdir -p ~/.gemini/skills/$NAME
```

Write `~/.gemini/skills/$NAME/SKILL.md`:

### Frontmatter

```yaml
---
name: $NAME
description: $DESCRIPTION
---
```

Only `name` and `description` are supported in Gemini skill frontmatter.

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

**Steps:** sequential (`Step 1, 2, 3`). Two modes: prefix `S1/A1`. Phases: `R1` (Research), `P1` (Plan), `I1` (Implement).

**Arguments:** received as `$ARGUMENTS`. Parse into named vars. Ask when required info is missing.

**Commands:** always show exact bash in code block. Use `$VARIABLE` placeholders. Explicit decision branches.

**Stop conditions:** `**Stop here.** <reason>` when blocking further progress.

**Guardrails:** read before editing; check preconditions before destructive steps; never `git add -A`.

## Step 4: Report

```
Created ~/.gemini/skills/$NAME/SKILL.md

Invoke with:  /$NAME [args]
```
