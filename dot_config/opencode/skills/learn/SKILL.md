---
name: learn
description: >
  Analyze the current session to extract learnings — corrections, confirmed
  patterns, new workflows — then propose targeted changes to skills for manual
  user approval. Use when the user says "what did we learn", "what should we
  remember", or at the end of a significant session.
allowedTools:
  - Bash(ls *)
  - Bash(grep *)
  - Read
  - Write
  - Edit
  - Skill
  - Todowrite
  - Todoread
---

# /learn — Session Learning Extractor

Scan the session for what was learned, then propose concrete changes to skills.
Nothing is applied without explicit user approval.

---

## L1: Scan the session

Read the entire conversation history in context. Look specifically for:

**Feedback signals (highest priority):**
- Corrections: "no", "don't", "stop doing X", "that's wrong", "not like that"
- Confirmations of non-obvious choices: "yes exactly", "perfect", "keep doing that", user accepting an unusual approach without pushback
- Repeated corrections on the same topic (strong signal)

**Workflow discoveries:**
- Tools or commands the user showed you that you didn't already know
- Patterns the user prefers for this repo/context (tool choices, naming, order of operations)
- Things that worked unexpectedly well or poorly

**New factual knowledge:**
- Project-specific facts (IDs, team names, URLs, configurations)
- Environmental constraints (which CLIs to use, which auth flows are needed)
- Decisions made (architectural, process, priority)

**Skill gaps:**
- Tasks where you had to ask clarifying questions that a better skill/memory would have answered
- Steps you got wrong that a richer skill description would have prevented
- Missing skills: tasks you handled ad-hoc that recur often enough to warrant a skill

---

## L2: Read current state

```bash
ls ~/.config/opencode/skills/
```

For any skills that were **used or triggered** in this session, read their SKILL.md to understand current content before proposing changes.

If active todos exist, read them too to understand what's in progress.

---

## L3: Build the proposal

Classify every finding into one of these buckets. Only include findings that are **non-obvious**, **not already recorded**, and **likely to recur**:

### Bucket A — Skill Improvements

For each skill: name the file, state what specific line/section to change, and show the before/after. Only propose changes with a clear, session-grounded reason.

Format:
```
[SKILL] ~/.config/opencode/skills/<name>/SKILL.md  (UPDATE)
Section: <section name or line range>
Reason: <what went wrong or what was confirmed>
Before:
  <current text>
After:
  <proposed text>
```

### Bucket B — New Skills Worth Creating

Only if a clear, recurring task was handled ad-hoc and has no existing skill:

```
[NEW SKILL] /<name>
Trigger: <when to invoke>
What it does: <one paragraph>
Why now: <what happened in session that revealed the gap>
```

---

## L4: Present and stop

Print the full proposal under this header:

```
## /learn — Session Learnings

### What we found
<1–3 sentences summarizing the session's main theme and what signals surfaced>

### Proposed Changes

<list all Bucket A, B items in order of impact — highest impact first>

---
To apply: tell me which items to apply (e.g. "apply A1, B2") or "apply all".
Changes are NOT applied until you approve them explicitly.
```

**Stop here.** Wait for the user to approve specific items before making any changes.

---

## L5: Apply approved changes (only after user approves)

For each approved item:

- **Skill (update):** Edit only the approved section of the SKILL.md. Match surrounding style.
- **New skill:** Create `~/.config/opencode/skills/<name>/SKILL.md` with the proposed content.
