---
name: loop-update-workdoc
description: >
  Recurring loop that watches recent coding-agent sessions (Claude Code and opencode),
  groups them by ticket or project, and folds each one into the shared workdoc — updating
  sections in place and managing Open items on its own. Use when the user says "loop
  update workdoc", "watch my sessions", "keep the workdoc current", "start the workdoc
  loop", or "auto-update the workdoc".
---

# /loop-update-workdoc — Workdoc Session Watch Loop

A self-scheduling cron loop. Each cycle: read which sessions moved since the last tick,
group them, update the workdoc.

**The write path lives in the `workdoc` skill** — read → decide update-in-place vs insert
→ UTF-16 indices → delete range → insert → verify, plus the entry format, the doc-id
config and every style/link trap. Read it at the start of a cycle and follow its Steps 0–6
for every write. This skill adds discovery, keying and scheduling.

## Hard rules — read every cycle

- **Never rewrite the body, never delete a section you did not create.** A section whose
  key stopped appearing is history, not garbage.
- **Never delete a human-written line.** Hand-written Open items get ticked, never
  removed. Bullets you cannot attribute to a session stay.
- **Cap the cycle at 6 sections.** More is a backlog: do the 6 oldest by `updated` and
  leave the rest for the next tick — they stay behind `last_tick`.
- **Skip your own noise.** Exclude the loop's own session id, and any group whose content
  hash is unchanged since it was last written.
- **One writer at a time.** A tick arriving mid-cycle is absorbed into the in-flight
  cycle, never started as a second one. Two cycles writing one doc at once is the exact
  failure the workdoc skill exists to prevent.
- Entries stay terse. Conclusions, not transcripts.

## State

`~/.config/workdoc/loop/` — outside any repo, so a torn-down worktree cannot take it away.

| File | Contents |
|---|---|
| `last_tick` | epoch ms of the previous cycle's start — the scan watermark |
| `sections.tsv` | `key<TAB>heading<TAB>content_hash<TAB>written_at<TAB>sources` |
| `README.md` | doc id, cron job id, this session's id |

`last_tick` advances only after a **verified** write. A failed cycle re-scans the same
window next time rather than losing the sessions in it.

## Step 1 — arm or confirm the cron job

`CronList` first. The job is session-only: it dies with the agent session, so a resumed
loop must re-create it. Recurring jobs also auto-expire after 7 days.

```
CronCreate cron="13,38 * * * *" recurring=true prompt=
  "/loop-update-workdoc — run one cycle."
```

Pick an off-minute (not `:00`/`:30`).

## Step 2 — scan sessions since the watermark

```bash
SKILL=~/.config/opencode/skills/loop-update-workdoc
STATE=~/.config/workdoc/loop
SINCE=$(cat $STATE/last_tick 2>/dev/null || echo $(( $(date +%s000) - 86400000 )))
NOW=$(date +%s000)
"$SKILL/scripts/scan_sessions.py" --since "$SINCE" --exclude-session "<this session id>" \
  > /tmp/workdoc-scan.jsonl
jq -sr 'group_by(.key)[] | [(.[0].key), length, ([.[].source]|unique|join(",")),
  (max_by(.updated_ms)|.updated)] | @tsv' /tmp/workdoc-scan.jsonl | sort -t$'\t' -k4
```

One JSON object per session, oldest first. Fields: `key source project session updated
request investigated learned completed next_steps notes`.

Sources (both sqlite; a missing one is skipped, and paths override with `--claude-db` /
`--opencode-db` or `$CLAUDE_MEM_DB` / `$OPENCODE_DB`):

- **claude-mem** `session_summaries` — one row per prompt-boundary summary, already
  carrying `request`, `investigated`, `learned`, `completed`, `next_steps`, `notes`. If
  claude-mem is not installed there is nothing to read: fall back to transcript mtimes
  under `~/.claude/projects/` only to detect *that* a session moved, never to summarise it
  (transcripts are far too large to read in a loop).
- **opencode** `session` + `part`, keyed on `time_updated`. opencode has no summariser, so
  those rows carry the title, the last three user prompts and the last assistant reply.
  Sessions with a short reply and no file changes are dropped as greetings.

An empty scan is a no-op cycle: touch nothing, leave `last_tick` where it is, re-arm, exit.

## Step 3 — key each group to a section

`key` is computed by the collector: a ticket id in the project or title wins; failing
that, a ticket mentioned in the body counts **only when the body names exactly one**
(several means the session was reading around, not working a ticket); failing that, the
project name. Two key shapes, two section shapes:

- **Ticket key** (`ABC-1234`) → the full entry format from the workdoc skill. Merge every
  session for that ticket into one section, whichever tool ran them.
- **Project key** (a repo or directory name) → a rolling digest section
  `## **<project> — recent work**`, **max 5 bullets, newest first**, one line each. Drop
  the oldest bullet rather than growing the section. An active repo can produce a couple
  of hundred untickered sessions a week; this is a digest, not a log.

Skip a group whose `sha256` of `completed|next_steps|notes` matches `sections.tsv`.

## Step 4 — write

Per group, run the workdoc skill's Steps 0–6. Fold the session fields in:

- `completed` → the ☑ bullets and the **Status:** line
- `next_steps` → the ☐ bullets
- `learned` / `notes` → **Notes:**, only when non-obvious
- `investigated` → dropped, unless it explains a ☐ that looks stalled

Then Open items, which this loop owns end to end:

- A ☐ per `next_steps` item needing a human or a later trigger. Name the ticket.
- Tick to ☑ when a later session's `completed` covers it. Ticked, not deleted.
- Never two ☐ for the same thing — re-word in place instead of adding a twin.

## Step 5 — close the cycle

1. Verify (workdoc Step 6): your sections present, links resolve, **no other section
   vanished**. If one did, another session overwrote it — restore it in the same write.
2. Write the `sections.tsv` rows, then `last_tick=$NOW` — only now.
3. Re-arm the cron job if it is gone or near its 7-day expiry (Step 1).

## Failure modes this loop has to survive

- Another session writing the doc mid-cycle → re-read before and after every write.
- A doc write reporting success on a wrong-index write → Step 5.1 is not optional.
- The summariser writing a row mid-scan → harmless; it lands after `NOW` and is picked up
  next tick.
- A session that produced nothing (greeting, aborted run) → already dropped by the
  collector; never create a section for it.
