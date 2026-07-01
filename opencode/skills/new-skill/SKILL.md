---
name: new-skill
description: Scaffold a new OpenCode skill following established conventions. Creates ~/.config/opencode/skills/<name>/SKILL.md with correct frontmatter, allowedTools, argument parsing, zellij label calls, and step structure. Use when adding a skill.
allowedTools:
  - Bash(test *)
  - Bash(mkdir *)
  - Bash(bash ~/.dotfiles/opencode/zellij-status.sh status *)
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

```bash
bash ~/.dotfiles/opencode/zellij-status.sh status "creating skill $NAME"
```

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

**allowedTools** (include only what's used):

| Capability | Entry |
|---|---|
| Git | `Bash(git *)` |
| Zellij status | `Bash(bash ~/.dotfiles/opencode/zellij-status.sh status *)` |
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

Zellij status (if multi-phase):
​```bash
bash ~/.dotfiles/opencode/zellij-status.sh status "verb context"
​```

Commands and logic.

## Step N: Report

​```
Done.
  Key: value
​```
```

### Conventions

**Steps:** sequential (`Step 1, 2, 3`). Two modes: prefix `S1/A1`. Phases: `R1` (Research), `P1` (Plan), `I1` (Implement).

**Zellij status** (required for 3+ steps or long-running): call at each phase start. `bash ~/.dotfiles/opencode/zellij-status.sh status "verb noun"`. No length limit — zellij truncates the pane title itself. Clear at end with `status ""`. For numeric counters use `progress N M "label"`.

**Arguments:** received as `$ARGUMENTS`. Parse into named vars. `AskUserQuestion` when required info missing.

**Commands:** always show exact bash in code block. Use `$VARIABLE` placeholders. Explicit decision branches.

**Stop conditions:** `**Stop here.** <reason>` when blocking further progress.

**Guardrails:** read before editing; check preconditions before destructive steps; never `git add -A`.

## Step 4: Report

```
Created ~/.config/opencode/skills/$NAME/SKILL.md

Invoke with:  /$NAME [args]
```
