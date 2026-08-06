---
name: learn
description: >
  Analyze the current session to extract learnings, auto-apply skill changes, and
  write durable findings into the auto-loaded memory directory. No user approval
  needed — findings are applied immediately.
allowedTools:
  - Bash(ls *)
  - Bash(grep *)
  - Bash(readlink *)
  - Bash(chezmoi managed*)
  - Bash(chezmoi diff*)
  - Bash(chezmoi apply*)
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

## L2: Know the surfaces that are actually read

Only these get loaded. Anything written elsewhere is lost.

| Surface | Path | Loaded when |
|---|---|---|
| Project memory | `~/.claude/projects/<project>/memory/MEMORY.md` + one file per fact | every session in that project |
| Global instructions | `~/.claude/CLAUDE.md` → symlink → `~/.config/opencode/instructions.md` | every session, all projects |
| Global rules | `~/.claude/rules/*.md` | every session, all projects |
| Skills | `~/.config/opencode/skills/<name>/SKILL.md` (`~/.claude/skills` is a symlink to the same dir) | when that skill runs |
| Observation log | `~/.config/opencode/skill-observations/log.md` | read by `task-observer` at session start |

Memory dirs are **per project and do not see each other**. Pick by directory name
(`-home-user-go-code` for `/home/user/go-code`, `-home-user--local-share-chezmoi` for the
dotfiles repo):

```bash
ls ~/.claude/projects/*/memory/MEMORY.md
```

A fact needed in two projects has to be written in both — that is duplication worth
paying for, not a mistake. Keep the second copy short and point both at the same wording.

**Do not write a `LEARNINGS.md`.** Nothing reads it. Earlier versions of this skill wrote
one at "workspace root", which here is either a dead file in `$HOME` or a stray untracked
file in the shared Uber monorepo. If one exists, fold its contents into memory (screening
per 4a) and ask the user before deleting it.

---

## L3: Resolve where each file is really edited

Three of the surfaces above are symlinks or chezmoi targets. Editing the target instead of
the source means the next `chezmoi apply` silently reverts your change. Resolve before
editing:

```bash
chezmoi managed | grep -E 'opencode/(skills|instructions)'
for d in ~/.config/opencode/skills/*/; do
  t=$(readlink "${d%/}"); [ -n "$t" ] && echo "$(basename "$d") -> $t"
done
```

Three origins, three edit locations:

- **chezmoi-managed** (most personal skills, plus `instructions.md`) — edit
  `~/.local/share/chezmoi/dot_config/opencode/...`, then
  `chezmoi apply <target-path>` and check `chezmoi diff` shows only your change.
- **work dotfiles** (symlinks into `~/.dotfiles-work/claude/skills/`, e.g. `babysit-pr`,
  `gh-status`, `jira`, the `ucsd-*` family) — edit the file under `~/.dotfiles-work/`;
  it is a separate repo with its own commits.
- **unmanaged** — edit `~/.config/opencode/skills/<name>/SKILL.md` directly.

Then read current state before writing anything:

```bash
cat ~/.claude/projects/<project>/memory/MEMORY.md
```

For skills **used or triggered** this session, read their SKILL.md. Most sessions
rediscover things already recorded. If active todos exist, read them too.

---

## L4: Build and apply

### 4a — Decide what is actually durable

Keep only findings that will change behaviour in a *future* session. Drop:
- anything `MEMORY.md` or an existing memory file already covers (update that file instead)
- anything the repo already records — code structure, git history, CLAUDE.md
- status that will be stale next week (PR numbers mid-flight, current CI state)
- procedure that belongs inside a specific skill (put it in that skill, see 4c)

**Screen anything you are migrating from a dead surface** (a stray `LEARNINGS.md`, old
notes) against the standing hard rules in `instructions.md`. Migration is not
transcription: a line that was never checked against current rules must be dropped, not
promoted. Moving it onto a loaded surface gives bad advice more authority than it had
while nothing was reading it.

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
- Edit at the origin resolved in L3 — chezmoi source, `~/.dotfiles-work/`, or the plain
  directory. Never edit a chezmoi target in `~/.config/`; the next apply reverts it.
- If the new instruction tells the skill to run a command, add that command to the skill's
  `allowedTools` in the frontmatter. A step the skill is not permitted to execute is not a
  fix.
- Match surrounding file style
- No approval needed — apply immediately

### 4d — Update global instructions or rules if the finding is standing behaviour

A correction that applies across projects — a changed hard rule, a workflow preference —
belongs in `~/.config/opencode/instructions.md` (chezmoi source
`dot_config/opencode/instructions.md`) or `~/.claude/rules/*.md`, not in one project's
memory. Editing a hard rule changes behaviour everywhere: confirm the new wording with the
user before writing it.

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
<files changed, with the origin each was edited at>

### Global instructions / rules updated
<what changed, or "none">
```
