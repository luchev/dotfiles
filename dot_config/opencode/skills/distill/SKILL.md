---
name: distill
description: >
  Mine accumulated memory for recurring lessons and promote the durable ones into
  tracked config — skills, global instructions, rules. Runs the opposite direction
  from /learn. Use when memory has grown large, when the same correction keeps
  recurring, or when the user asks to consolidate memory into how they work.
allowedTools:
  - Bash(ls *)
  - Bash(grep *)
  - Bash(wc *)
  - Bash(readlink *)
  - Bash(git -C * remote*)
  - Bash(gh repo view*)
  - Bash(chezmoi managed*)
  - Bash(chezmoi diff*)
  - Bash(chezmoi source-path*)
  - Read
  - Write
  - Edit
  - Glob
  - AskUserQuestion
---

# /distill — Memory to Config Promoter

`/learn` writes session findings **into** memory. `/distill` reads accumulated
memory and promotes the recurring ones **out** into config that loads
automatically. Memory answers "what happened in this project." Config answers
"how I work everywhere." A lesson that has proven itself across projects belongs
in the second.

Nothing is deleted. Memory stays canonical; promotion copies a lesson to a
surface that loads without being searched for.

---

## D1: Gather

Read from both, because they can disagree:

```bash
ls ~/.claude/projects/*/memory/*.md          # canonical markdown
grep -rl "" ~/.config/opencode/skill-observations/log.md
```

If claude-mem is installed, also query it for cross-project clusters — it sees
across project boundaries that the per-project memory dirs cannot. If it is not
installed or its worker is down, fall back to the markdown alone and say so;
never silently distill from a partial view.

Memory dirs **do not see each other**. A lesson living in three project dirs
under three different filenames is the single strongest promotion signal, and it
is invisible unless you look across all of them.

## D2: Cluster

Promote on evidence, not on whether something sounds general.

| Signal | Threshold |
|---|---|
| Same lesson in ≥2 project memory dirs | promote |
| Correction repeated ≥3 times in one project | promote |
| Feedback memory contradicting current config | promote — config is stale |
| Single occurrence, however well written | leave in memory |

A single vivid lesson is the most common false positive. One occurrence is a
fact about one project; it stays where it is.

## D3: Classify the destination

| Kind of lesson | Destination |
|---|---|
| Procedural — a flag, an ordering, a command that breaks without a TTY | the relevant `SKILL.md` |
| Standing behaviour across all projects | `dot_config/opencode/instructions.md` |
| Hard rule, safety, or always-on style | `dot_claude/rules/*.md` |
| Project-specific fact — IDs, hostnames, one repo's conventions | **stays in memory** |

The last row is most of memory and that is correct. Promotion is for the
minority that generalised.

For the authoritative map of which files actually get loaded and when, use the
**L2 surfaces table in `learn/SKILL.md`** rather than restating it here — one
copy, one place to fix.

## D4: Sensitivity screen — mandatory, non-skippable

Runs before any write to a tracked file. Not a caveat, a gate.

Resolve the destination repo's visibility first:

```bash
git -C ~/.local/share/chezmoi remote -v
gh repo view <owner/repo> --json visibility,isPrivate
```

Memory accumulates from real work, so it contains employer-internal detail:
internal hostnames, ticket field IDs, service names, LDAP identity, gateway
URLs, internal tooling names. A dotfiles repo is frequently public. Publishing
to one is irreversible — public repos are cached, forked, and indexed regardless
of any later deletion.

If the destination is public, then for every candidate promotion:

- Strip the internal specifics and promote only the generalised rule, or
- Leave it in memory entirely.

Never promote a lesson whose *value depends on* the internal specifics — a rule
that only works with the internal detail attached is a rule that belongs in
memory. When uncertain whether something is internal, treat it as internal and
ask.

State the screen's result explicitly in the summary. "Screened, N held back" is
information; silence reads as "nothing was sensitive," which is a different
claim.

## D5: Resolve where each file is really edited

Every destination in D3 is a chezmoi source path, never the `~/.config/` or
`~/.claude/` target. Editing a target means the next `chezmoi apply` reverts it.

Follow the **L3 resolution procedure in `learn/SKILL.md`**. Two additions:

- `chezmoi diff` requires the **absolute target path**. Given a source-relative
  path it reports `not managed`, which looks identical to a clean result.
- Third-party installers write to targets through symlinks. If a tool was
  installed since the last distill, diff source against target before editing so
  its changes are propagated rather than clobbered.

## D6: Propose, then write

Promotion changes behaviour in every future session, so it is not auto-applied —
this is the deliberate difference from `/learn`, which auto-applies because a
session finding is cheap to undo and a standing rule is not.

For each promotion show: the lesson, its evidence (which projects, how many
occurrences), the destination file, and the exact diff. Get approval. Then:

- Write to the chezmoi source.
- Match the surrounding file's style and density.
- If a promoted instruction tells a skill to run a command, add that command to
  the skill's `allowedTools` — an instruction the skill cannot execute is not a
  fix.
- Leave the source memory file in place. Add a line noting it was promoted and
  where, so the next distill does not re-propose it.

Verify before reporting done:

```bash
chezmoi diff ~/.config/opencode/instructions.md   # absolute path
```

## D7: Summary

Report: candidates found, promoted (with destinations), held back by the D4
screen, and left in memory as project-specific. If nothing cleared the D2
thresholds, say that plainly — a distill run that promotes nothing is a normal
outcome, not a failure, and padding it with weak promotions is how config rots.
