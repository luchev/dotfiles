---
name: learn
description: >
  Analyze the current session to extract learnings, auto-apply skill changes, and
  write durable findings into the auto-loaded memory directory. No user approval
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

Scan the session for learnings → extract them → auto-apply skill changes → write the durable ones into the **memory directory**, which is the only surface actually loaded next session.

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

## L2: Find the memory directory

Durable learnings go in the project's memory directory — `MEMORY.md` plus one file per
fact — because that is what gets loaded into context at the start of every session.

```bash
ls ~/.claude/projects/*/memory/MEMORY.md
```

Pick the one whose directory name matches the repo you are working in (e.g.
`-home-user-go-code` for `/home/user/go-code`).

**Do not write a `LEARNINGS.md`.** Nothing reads it, so anything put there is lost. Earlier
versions of this skill wrote to `LEARNINGS.md` at "workspace root", which here is either a
dead file in `$HOME` or a stray untracked file in the shared Uber monorepo. If a
`LEARNINGS.md` already exists, fold its contents into memory and delete it.

---

## L3: Read current state

```bash
ls ~/.config/opencode/skills/
cat ~/.claude/projects/<project>/memory/MEMORY.md
```

For skills that were **used or triggered** this session, read their SKILL.md before proposing changes.

Read `MEMORY.md` before writing anything — most sessions rediscover things already recorded.
If active todos exist, read them too.

---

## L4: Build and apply

### 4a — Decide what is actually durable

Keep only findings that will change behaviour in a *future* session. Drop:
- anything `MEMORY.md` or an existing memory file already covers (update that file instead)
- anything the repo already records — code structure, git history, CLAUDE.md
- status that will be stale next week (PR numbers mid-flight, current CI state)
- procedure that belongs inside a specific skill (put it in that skill, see 4c)

### 4b — Write memory files

One fact per file in the memory directory, with frontmatter:

```markdown
---
name: <short-kebab-case-slug>
description: <one-line summary — used to decide relevance during recall>
metadata:
  type: user | feedback | project | reference
---

<the fact; for feedback/project add **Why:** and **How to apply:** lines>
```

`feedback` for corrections (include the why — a rule without its reason gets misapplied),
`reference` for reusable technique or external pointers, `project` for ongoing work,
`user` for who the user is. Link related memories with `[[slug]]`.

Then add **one line** to `MEMORY.md`: `- **Hook**: one-sentence gist. See [file.md](file.md).`
Never put the content itself in `MEMORY.md` — it is an index.

### 4c — Update skills (auto-apply)

Procedural findings — a command that needs a flag, a prompt that breaks without a TTY, an
ordering that matters — belong in the relevant SKILL.md, not in memory. A skill is loaded
when it runs, so that is where the fix takes effect.

For each skill improvement found:
- Edit the SKILL.md file directly (chezmoi source if managed, otherwise ~/.config/opencode/skills/)
- Note that `~/.claude/skills` is a symlink to `~/.config/opencode/skills` — same files, edit once
- Match surrounding file style
- No approval needed — apply immediately

### 4d — Update project CLAUDE.md if findings are project-level

If learnings include project conventions, environment details, or standing instructions that belong in CLAUDE.md, append them to the relevant section.

**Do not edit a CLAUDE.md that is checked into a shared repo** (e.g. `go-code/CLAUDE.md`) —
that is a change other engineers own. Put it in memory and tell the user instead.

---

## L5: Print summary

Print:

```
## /learn — Applied

### Memories written
<file — one-line gist, per memory added or updated>

### Skills updated
<files changed>

### Project CLAUDE.md updated
<what changed, or "none">
```
