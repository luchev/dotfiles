---
name: learn
description: >
  Analyze the current session to extract learnings, auto-apply skill changes, and
  append bullet-point summaries to the project's LEARNINGS.md. No user approval
  needed — findings are applied immediately.
allowedTools:
  - Bash(ls *)
  - Bash(grep *)
  - Read
  - Write
  - Edit
  - Skill
  - Todowrite
  - Todoread
  - Glob
---

# /learn — Session Learning Extractor (auto-apply)

Scan the session for learnings → extract bullet points (1 sentence each) → auto-apply skill changes → append to `docs/LEARNINGS.md` or `LEARNINGS.md`.

---

## L1: Scan the session

Read the entire conversation history. Look for:

**Feedback signals (highest priority):**
- Corrections: "no", "don't", "stop doing X", "that's wrong", "not like that"
- Confirmations of non-obvious choices: "yes exactly", "perfect", "keep doing that"
- Repeated corrections on the same topic (strong signal)

**Workflow discoveries:**
- Tools or commands the user showed you that you didn't already know
- Patterns the user prefers for this repo/context
- Things that worked unexpectedly well or poorly

**New factual knowledge:**
- Project-specific facts (IDs, configs, URLs)
- Environmental constraints
- Decisions made (architectural, process, priority)

**Skill gaps:**
- Tasks where you had to ask clarifying questions that a better skill would have answered
- Steps you got wrong that a richer skill description would have prevented
- Tasks that recur often enough to warrant a skill

---

## L2: Determine project root and learnings file path

- If `docs/LEARNINGS.md` exists at workspace root → use that
- Else if `LEARNINGS.md` exists at workspace root → use that
- Else → use `LEARNINGS.md` at workspace root (will create)

---

## L3: Read current state

```bash
ls ~/.config/opencode/skills/
```

For skills that were **used or triggered** this session, read their SKILL.md before proposing changes.

If active todos exist, read them too.

---

## L4: Build and apply

### 4a — Compile learnings as bullet points

Each bullet = 1 short sentence. Group by category (Corrections, Workflow, Facts, Decisions).

### 4b — Append to LEARNINGS.md

Date-stamped section. If file doesn't exist, create it. Append format:

```markdown
## 2026-07-25 — <session topic>

- <one short sentence per finding>
- <...>
```

### 4c — Update skills (auto-apply)

For each skill improvement found:
- Edit the SKILL.md file directly (chezmoi source if managed, otherwise ~/.config/opencode/skills/)
- Match surrounding file style
- No approval needed — apply immediately

### 4d — Update project CLAUDE.md if findings are project-level

If learnings include project conventions, environment details, or standing instructions that belong in CLAUDE.md, append them to the relevant section.

---

## L5: Print summary

Print:

```
## /learn — Applied

### Learnings written to docs/LEARNINGS.md
<bullet list of what was written>

### Skills updated
<files changed>

### Project CLAUDE.md updated
<what changed, or "none">
```
