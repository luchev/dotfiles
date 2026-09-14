---
name: loop-watch-oncall
description: >
  Recurring loop that sweeps every alert definition on an oncall rotation, investigates
  each new firing to a root cause with proof links, writes the findings into a per-shift
  Google Doc tab, and refreshes one rolling Slack DM — WITHOUT acking, resolving or
  annotating anything on the oncall dashboard. Schedules itself. Use when the user says
  "watch my oncall alerts", "loop watch oncall", "resume the oncall loop", "start the
  alert watch loop", or asks to investigate what fired on the rotation this shift.
---

# /loop-watch-oncall — Oncall Alert Watch Loop

A self-scheduling cron loop. Each cycle: enumerate everything that fired this shift,
investigate what is new, re-measure what is still open, write it up, refresh one rolling DM.

`~/.claude/oncall-watch/README.md` is the **accumulated-knowledge log** — per-class prior
art, every trap this loop has hit, and the tooling corrections that have not yet been
promoted here. Read it at the start of every cycle. This file is the standing procedure;
new findings get appended there, and only procedure gets promoted into this file.

---

## 0. The loop schedules itself

On invocation, before anything else:

1. `CronList`. **The cron job is session-only** — it dies with the Claude session that
   created it and nothing on disk restores it, while the state directory keeps advancing
   either way. A healthy-looking state tree is not evidence the loop is running.
2. If no job is scheduled, create one:

```
CronCreate cron="17,47 * * * *" recurring=true prompt=
  "/loop-watch-oncall — run one cycle. Rotation <name> <rotation_id>, shift <shift_id>
   (<start>..<end>), dashboard/team <team_uuid>. Google doc <doc_id>, current tab <tab_id>
   '<tab title>'. Slack DM channel <channel_id>, rolling message ts <ts>."
```

   Off the :00/:30 marks on purpose. Recurring jobs auto-expire after 7 days — say so when
   you schedule one.
3. If the shift in the cron prompt has ended, roll over (§7) and re-create the job with
   the new ids before running the cycle.

Then run one cycle: §1 → §8.

---

## Hard rules — read every cycle

- **Never ack, resolve, or annotate.** Investigation only. The dashboard must look
  untouched when the loop is done. The doc carries a paste-ready annotation block; the
  user posts it.
- **Never edit another engineer's annotation.** Their verdict is a hypothesis like any
  other: test it, and if the evidence disagrees report that to the user.
  `movealertstoannotation` on a firing inside someone else's annotation strips it out.
- **Open LOW alerts ARE investigated.** Only HIGH-urgency alerts wait until they resolve
  before anything is written.
- **Every claim carries a clickable proof link.** A described query is not a proof.
- **Every root-cause and impact claim gets a red-team subagent** briefed to *refute* it,
  before it ships. Independent claims in parallel. Re-challenge every open, not-yet-
  annotated class already in the doc. **Spawn them unnamed** — a named background agent
  can go idle without ever delivering, and `TaskOutput` will not find it.
- **Read the runbook first**, at the start of every investigation. Once a class is
  challenge-cleared, open a Jira task proposing a runbook update — the task only, never
  edit the runbook.
- **Corrections replace text, they do not accumulate.** The doc is an executive summary of
  the current truth, never a changelog. `RETRACTED`, `CORRECTED`, "an earlier revision
  said", "superseded figures follow" are banned in the doc; that history belongs in the
  Jira thread. Re-read this list before writing any line that revises an earlier one — that is
  exactly when the urge to label the revision appears, and it has slipped through once.
- **If the runbook cannot be read, record it UNREAD in the doc.** The wiki MCP disconnects
  mid-session; the tiny-link decode still yields the page id for later. Never let a tooling outage
  turn into a silently skipped step.
- **Aggregate before you generalise.** Never a population claim from one sampled row.
- **Measure the gate before naming alert arithmetic as the cause.** `sustain`, `keepLastValue`,
  `moving` and duty cycle make a story that sounds mechanical and explains the observation — and it
  has been refuted by direct measurement twice. Compute the actual continuous runs over threshold
  and the actual evaluation unit (`ALERT_TYPE_ZONAL` means a fleet-collapsed view is the wrong
  frame). If the gate is satisfied and the alert still did not fire, the cause is downstream of it.
- **Do not reach for "the alert is wrong."** Prove the event was benign first.
- **A proven mechanism is not a proven urgency.** After a source read establishes what a metric
  means, pull a quiet-period BASELINE before concluding anything about severity, then write the
  narrowest claim the evidence supports. "This alert's construction is wrong" and "there is an
  urgent problem" are different tickets — and when contradicting someone else's annotation, say
  which part of their verdict still stands.
- **"Not our alert" is not "not our problem."** A platform alert can still mean our defect.

---

## State

`~/.claude/oncall-watch/`, outside any repo:

| File | Holds |
|---|---|
| `README.md` | accumulated knowledge; per-class prior art; the learnings log |
| `defs_all.tsv` | `uuid<TAB>service<TAB>alert-name` for every swept alert definition |
| `known_defs.txt` | union of every def known to have fired this shift |
| `seen_alerts.txt` | firing uuids already investigated — **including ones deliberately skipped** as foreign-rotation, so they are not re-checked every cycle. **Union it, never overwrite it**: `sort -u old this_cycle dashboard_ids` — copying a cycle's firing list over the file silently drops the skipped ids and they come back as NEW |
| `deferred_low_open.txt` | open LOW firings carried between cycles |
| `deferred_high.txt` | HIGH firings skipped while open, re-checked every cycle until investigated |
| `probe.sh` | `<uuid> <svc> <name>` → a hit line, or `ERR` if the call never succeeded |

`probe.sh` reads `WIN_FROM`/`WIN_TO` from the environment, so a shift rollover needs no
code edit.

---

## 1. Sweep

Sweep **one SLICE of `defs_all.tsv` per cycle, serially, rotating** — next index in
`sweep_slice.txt`. Union the hits with `known_defs.txt`, diff against `seen_alerts.txt`.

**The workable slice size shrinks over a long session.** Ladder so far: ~1030 clean for several
cycles then killed 04:23Z on 09-11; ~510 clean for several cycles then killed 08:53Z; ~257 killed
minutes later; **~130 works**. When a slice is killed, SPLIT it and run the pieces **sequentially
inside one task** — each piece then finishes and releases before the next starts, which is not what
happens when separate background tasks overlap. Quartering a twice-killed slice restored its full
coverage in one cycle, returning exactly the defs its last good pass had.

**Dedupe the combined output before counting.** With an injected canary in one piece, a def that is
real in another piece appears twice; that turned 5 raw lines into 4 distinct defs. Only the deduped
set goes into `known_defs.txt`.

Do not try to predict the next size from the cgroup — kills have landed at 62, 58, 57 and **38.4
GiB, the lowest reading of the session**. The growth is in zellij (7.45 → 12.06 GB over ten hours),
so the budget shrinks for reasons the loop cannot tune away.

Parallelism was walked all the way down by evidence and then ran out: 16-way threw throttled `ERR`
rows and was killed for memory; 8-way was killed after several clean cycles; 4-way was killed
2026-09-10 20:26Z; 2-way at 22:53Z; **serial itself was killed at 00:20Z on 09-11**, with 43 GiB
free inside the cgroup cap. Slicing is what is left.

**Say the coverage gap out loud in the doc and Slack**: a brand-new def that has never fired this
shift, sitting in a slice not swept this cycle, is missed until its slice comes round. Everything
already firing is still caught every cycle by the `known_defs.txt` union re-query.

**The canary must belong to the slice being swept AND be firing NOW.** A global canary reads as a
void sweep on every slice that does not contain it — slice 0 returned `canary: 0` for exactly that
reason. But do not just take the first `known_defs.txt` entry in the slice either: that file
accumulates and 13 of its 29 entries return `{}` every cycle, so a stale pick marks a good sweep
void. Choose a def with a current firing.

**At quarter granularity, verify every canary against that slice's own LAST GOOD PASS**, not against
`known_defs.txt`. The known set is a union over the whole shift; the last good pass is the only list
of defs actually firing in that range now. `q4_00` drew `b25317b3` as the first known-def in its
range and it was one of the 13 stale entries — it would have marked a clean sweep void. The smaller
the piece, the higher the odds of drawing a stale one, because each piece holds fewer defs.

**If a slice contains NO currently-firing def, inject one into its input list.** At six sub-slices
one of them held nothing from the firing set, so no canary was possible and `0 hits, ERR 0` there
would have been indistinguishable from a sweep that never ran. Appending a known-firing def's line
to that slice's input costs one probe and restores the check; merging the slice into a neighbour
just rebuilds a unit size that already gets killed. **The injected canary is a probe, not a
finding**: never count it in the slice's hit total or add it to `known_defs.txt` — with a def not
otherwise known that would contaminate the known set. Sub_01 ran with zero real hits and only the
canary line, which is the intended outcome, not an empty sweep.

**Keep the slice files in `~/.claude/oncall-watch/slices/`, not `/tmp`.** A `/tmp` cleanup takes the
canary injection with it and the regenerated slice reverts to unvalidatable, silently.

Six-sub-slice canaries as of 09-11: sub_00 `0685b3af`, sub_01 `0685b3af` (injected), sub_02
`5904f5b3`, sub_03 `881880a2`, sub_04 `bc1a877a`, sub_05 `eae887a9`. **Re-derive them whenever
`defs_all.tsv` is rebuilt or the firing set changes** — a canary that stops firing becomes a stale
pick, the same trap in slower form.

**The rotation reconciles.** Slices 0, 1 and 2 return 3 + 9 + 2 = 14 firing defs, identical to what
every full 3092-def sweep returned before the kills. Re-run that check whenever `defs_all.tsv` is
rebuilt — it is the evidence that slicing loses nothing over a full rotation.

**A cron tick that arrives while a sweep is running is ABSORBED into the in-flight cycle, never
started as a second cycle.** Cycles run longer than the 30-minute cron, so this is the normal case.
A second concurrent sweep compounds the memory pressure behind the kills, and interleaved gateway
calls return 429s indistinguishable from empty results. Check for live `probe.sh` processes first.

- **Reap orphaned probe processes BEFORE sweeping.** `probe.sh` retries up to 4 times per def and
  each attempt spawns an MCP-CLI process; interrupted sweeps leave dozens alive. They accumulated to
  96 across one session and the OS killed a sweep for low memory. Check `pgrep -cf '<mcp-cli>'` and
  reap first — but build the pattern so it cannot match its own command line, or `pkill` kills the
  shell running it and returns a bare **exit 144**, or a bare **exit 1**, with no output at all:
  `P='mcp-cl''i'; Q='pro''be.sh'; pkill -9 -f "$P" >/dev/null 2>&1; pkill -9 -f "$Q" >/dev/null 2>&1`
  This applies to EVERY pattern you reap on, `probe.sh` included — it has bitten both. **Put the
  reap in its OWN command**: the split-string trick fails the moment anything else in the same
  command line contains the real literal, and combining the reap with an actual MCP call
  killed the shell exactly that way.
- **A killed sweep is VOID, not quiet.** Check the task status. Chunk files with a plausible number
  of hit lines will be sitting on disk regardless; re-run rather than reporting from them. Drop the
  parallelism a notch and re-run — sweeps have been killed at 16-way, 8-way, 4-way and 2-way, so
  slicing is the fallback — serial over the whole list was killed too.
- **Judge memory by the CGROUP, never by `free`.** `free -m` describes a host this process cannot
  use all of; `/sys/fs/cgroup/memory.max` and `memory.current` are what enforce. One session
  declared memory "healthy" at 262 GB host-available while the cgroup sat at 55 GiB of a 96 GiB cap
  and killed the next sweep. `/tmp` here is ext4 on disk, not tmpfs, so files there cost no RAM —
  do not go hunting them. **A healthy cgroup reading does not mean the sweep will survive**: the
  09-10 4-way kill came at 57 of 103 GiB, 45 GiB inside the cap, from host-level pressure the
  cgroup cannot see. Use the cgroup to rule memory OUT as an excuse, never to rule a kill out.
  **A FALLING `memory.current` is not relief either.** It dropped 62.0 → 52.9 GiB while the process
  table in the same command showed zellij up 9.59 → 10.65 GB: that was page cache being reclaimed
  over a still-growing leak. Read `memory.current` and `ps -eo rss --sort=-rss` together, and never
  size slices up on the cgroup number alone.
- **`setopt nullglob` first, in every command of the cycle**, not only the sweep. In zsh a glob
  with no match returns non-zero and kills the whole `&&` chain — the sweep then prints a clean
  `HITS: 0` having never run. A stray `rm -f /tmp/…/chunk_*` cleanup hit it again on 09-10.
- **`split` in its own command**, before the loop, if you ever go back to chunking.
- **Assert the canary.** After the sweep, grep the chunk output for a def known to have
  fired this shift. No canary hit ⇒ the sweep is **void**, not quiet. Assert it with `grep -c`
  alone and read the number — no arithmetic, no external binaries. A canary piped through `bc`
  printed `command not found` and produced no count, which looks much the same as a canary that
  missed.
- **Count the `ERR` lines.** Any `ERR` row means the sweep is incomplete. Re-probe those
  uuids individually. Do not retry-loop the whole sweep. Capture the ERR uuids *before*
  deleting the chunk files — an ERR'd def is absent from the hit list and looks exactly
  like a def that stopped firing.
- **A zone-keyed def's firings are one condition handing off between evaluating zones.**
  `incident_key` is `<zone>|<alert name>|<service>`. On an `ALERT_TYPE_ZONAL` def each resolve is
  followed by the next firing seconds later under a different zone, so the per-def firing count is
  re-notification, not recurrence. Read `incident_key` before counting events, and when such a
  chain ENDS, re-measure the condition — a resolve with no successor is not evidence it cleared.
  Compute the gap DISTRIBUTION before calling a chain broken: one def's four handoffs ran 32s,
  2m26s, 2m26s and 6m07s, and a 6-minute gap was read as a break against a 2m30s "cadence" taken
  from the first three.
- **The ocdash index lags creation by more than a few seconds.** A re-query at 21:42:04 returned
  four firings while a fifth, created 21:41:57, was absent — and that absence is what made a live
  chain look broken. A "nothing yet" reading taken seconds after the expected event is unknown,
  not evidence; wait a cycle.
- **Check whether the metric has ONE emitter at a time.** Group by the emitter tag over the whole
  shift and test for overlap. If the emitters never co-emit, the def's firing count counts LEADER
  MOVES, not events, and every resolve is data absence rather than recovery — confirm by reading
  the last sample before each resolve (104, 111, 49, 34 against critical 5, on one def). Sustain
  explains the ONSET lag only; do not assume the resolve lag is the moving window plus sustain,
  which predicted 35 minutes against an observed 27. `transformNull 0` reads 0 during the gap, so
  the def cannot distinguish recovery from silence and neither can you — label that UNTESTABLE.
- **Group the metric by the EMITTER as well as the subject.** The alert's own query may group by a
  subject tag (`subject_zone`, 9 series) while the incident is keyed by the emitting zone
  (`emitter_zone`, 2 series). Measuring only the subject cannot tell you what the firing zone saw.
  Check the tag list first: this metric has no `zone` tag at all, and `sumSeries zone` returns 0
  series, which reads like a dead metric rather than a wrong tag name.
- **Two correlated defs are not a clock.** The staging fence/fingerprint pair was documented as
  re-notifying "in lockstep, four seconds apart, every 30 minutes". Measured over a longer window
  the firing gap ranges 2-47s, the resolve gap reaches 2m15s and inverts order, and open duration
  ranges from ~30 minutes to 8h12m. Use a sibling as corroboration; never infer "same event" from
  a close timestamp.
- **Diff on firing uuids, never on per-def counts.** Sweeps are not perfectly stable; a
  def that fired once may drop out of a later one.
- **Query the UNION** of this sweep's defs and `known_defs.txt`, every cycle. A sweep that
  drops a def which has a brand-new firing would otherwise hide it entirely.
- **Assert per-def CONTENT, not file existence.** `[ -s file ]` passes on an error message. On
  2026-09-10 nine of 29 known-def files held
  `request failed: Post "https://mcp-gateway...": dial tcp`, and the result read as 41 firings
  dropping to 29 with two open alerts resolving — both on defs in the failed set. Re-querying those
  nine restored the real numbers. Check content, accepting `{}` as the legitimate "no firings"
  answer:
  `for f in kd_*.json; do grep -q '"alerts"\|^{}' "$f" || echo "SUSPECT $f"; done`
  Re-query the suspects, confirm zero remain, and only then diff. **Apply this to every fan-out of
  API calls, not just the sweep** — `probe.sh` already had ERR handling for exactly this failure
  shape, but the re-query that runs straight after it did not.
- **The two alert APIs use OPPOSITE id field names.** The by-definition firings API keys them
  `.uuid` (`uuid, incident_key, status, urgency, created_on, resolved_on, last_status_change_on,
  alert_uuid, head_uuid, pd_id, incident_source, first_annotation,
  alerting_value_timestamp, all_assignees` — no `id`); `search` results are keyed `.alert.id`
  (`created_on, details, head_id, id, pd_id, rotation_ids` — no `uuid`). Each returns null for the
  other's name, with no error: `.id` on the by-definition path gave 41 nulls that read as one NEW firing
  called `null` plus every open alert resolved, and `.alert.uuid` on the search path gave 0 distinct
  ids against a `result_count` of 18, which reads exactly like the flaky index. **When an id
  extraction returns zero rows or nulls, print the object's keys before believing the API.** Never
  paper over it with a `// .other_field` fallback — that hides the mismatch instead of finding it.
- Guard the diff: `[ -s new.txt ] && grep -F -f new.txt firings.txt || echo "  (none)"`.
  `grep -F -f` with an empty pattern file matches **every** line.

**Rebuild `defs_all.tsv` at the START of the shift, before the first sweep**, from the rotation's
alert groups — not a fixed service list. It goes stale in two silent directions at once: a service
missing from the list hides all of its defs, and a def created after the build is absent even when
its service IS covered.

This is not a completeness nicety. On 2026-09-10 a rebuild took the list from 2740 defs over 8
services to 3092 over 9, and the first sweep on it returned **13 firing defs against the old list's
8** — including **two PAGE_URGENCY_HIGH firings** and a staging alert already open 29 hours, while
the loop had been reporting the shift as all-LOW. A stale list does not degrade gracefully: the
canary still passes, because the surviving defs still fire. **Until a sweep has run on a freshly
built list, do not characterise the shift's urgency mix at all.**

Rebuild from the platform's per-service definition-list call (all statuses, not just failing),
keeping every object that has an id, a `name` and a `query`.

## 2. Run the dashboard search too — it is half the shift

The sweep only covers defs the monitoring platform holds. Deploy-platform alerts
(`Deployment rolled back`),
host-agent alerts and some service alerts have no def and page the rotation anyway.

```
<dashboard>_search {queries:["<team term>"], page_size:20, page_number:N,
  created_after:<shift start>, created_before:<shift end>, type_filter:"",
  team_uuid:<dashboard id>}
```

- `page_size` >20 returns `{}`. Page until a page returns no `query_results`.
- The index is flaky — an empty first page is **unknown**, not empty. Re-run until a
  known-good query returns non-zero.
- Shape: `.query_results[0].alerts[].alert.{id,created_on,details.summary,details.links}`,
  and `result_count` at `.query_results[0].result_count`. Only one query term matches the team — find it once and pin it.
- **The result set ROTATES behind a fixed count.** `result_count` read 13 on every call while
  eight repeated identical calls returned **14 distinct** alerts, members swapping in and out. A
  single call is a sample, not the population. Call it several times and union.
- **`details.links[]` is the def-less discriminator**, not absence from `defs_all.tsv`. The
  `linkToAlert` URL's `/alerts/<uuid>` IS the alert-definition id and works with the
  get-definition call.
  A genuinely def-less class (the deploy-platform rollbacks) has an EMPTY links array.

## 3. Investigate each new class

Runbook → alert definition → the metric behind it → logs → the source that emits both.
**Read the implementation before asserting semantics from a name.** Several findings in
this loop turned on a metric, tag or status meaning the opposite of what it reads like.

**Search the whole of `src/`, not the owning team's directory.** Two questions sat UNVERIFIED for
several cycles each purely because the greps were scoped to the owning team's directory: one
metric's `status` tag was built in a neighbouring team's shared metrics package, and a host-agent
subscription limiter lived in a platform package. If a symbol is not where it
"should" be, widen the path before concluding it is absent.

- Alert def: the platform's get-definition call. Field names there are strict — one spelling
  works, every other is rejected and the error names no alternatives. Pin the working one.
- **A class with no def** still has a query: base64 JSON in `listannotationsforalert` →
  `annotations[].alerts[].metadata`, carrying the alert query, name and runbook.
- Check `listannotationsforalert` before writing anything. `{}` means unannotated.
- **Runbook links are often Confluence tiny links** (`<wiki-host>/x/<tok>`). Following the
  redirect needs browser auth; decode instead — `-`→`/`, `_`→`+`, pad to 4, base64, then
  `struct.unpack('<q', b[:8])` gives the page id for `confluence_get_page`. A page can return
  successfully and still be the unfilled TEMPLATE, with only its first line written. That is a
  finding worth a runbook task, not a read failure.
- **Compare sibling defs by reading the whole `.star` block in one `git show`**, rather than
  querying defs one at a time. That is how a missing `objecttype:!{...}` filter was shown to be an
  omission: present on all three stuck-rollout defs predating the tier split, absent from both it
  added. Per-def API calls would not have shown the three older defs agreeing.
- **Date an alert change from the COMMIT, never from `created_at`/`last_updated`.** Those are
  deploy-propagation times and can trail the change by a day. Two defs sharing a `created_at` to
  the half-second proves nothing — it is equally consistent with a bulk re-apply. Find the change
  in `config/infra/starlark/teams/config/alerts/<service>.star`: `git log --oneline -- <path>`
  then `git show`. The commit message usually states the intent outright, and a def is often tuned
  again in later commits.
- **Find the near-miss twin.** When a threshold alert fires, search the same shift for a breach of
  similar magnitude that did NOT fire. If one exists, the difference between them is the mechanism,
  and it is usually not severity. Two 40000 breaches on the same def: one followed 20s later by a
  normal sample (no page), one landing last before a gap so `keepLastValue` completed the sustain
  on held data (paged).
- **Run the alert-vs-config check FIRST on any threshold alert** — compare the threshold
  against the service's own tuning (memlimit `allocation_percentage`, rate limits,
  timeouts). It can end an investigation in minutes: a service's "Memory Usage is High"
  warns at 90% while the service sets GOMEMLIMIT to 90%, so it fires by construction.

### Inherited explanations are hypotheses

A previous shift's verdict, a runbook, a ticket's stated mechanism — all hypotheses. Test
them and say so. In one shift this overturned four inherited explanations: a "soft-deleted
object" theory that was really a zone blackout, a "recently added zone" that had been active
three months, a ticket whose stated mechanism was wrong, and a "known issue" memory alert
that was a threshold misconfiguration.

## 4. Re-measure every open class, every cycle

**A HIGH alert left open must be picked up when it resolves.** Leaving it alone while it is
still triggered is correct, but it creates a class of firing no later cycle looks at: the uuid
is already in `seen_alerts.txt`, so the diff will never surface it again. One resolved 42
minutes after firing and was still unannotated a day later. Keep those uuids in
`deferred_high.txt`, re-check their status every cycle before the diff, and drop one only
once it has been investigated.

**Record a dated prediction whenever a mechanism implies something checkable, and test it next
cycle.** A mechanism that already survived a red team does not need more supporting evidence; it
needs a forward test, and a prediction is the one kind that can fail. It also costs nothing, since
the loop runs again anyway. Write it into the doc with an expected time, mark it unresolved, and
record the outcome either way.

**Re-read every status band each cycle, not only the sections you edited.** Relative ages ("open
29h") and phrases like "this cycle" rot faster than the evidence under them — three bands were
wrong on one re-read. Prefer absolute anchors.

An open alert on an already-explained class is not "nothing to do" — the alert status looks
identical whether the underlying set grew, shrank or changed shape. Re-measure the
condition and diff against the last measurement, keeping the **identity list** and not just
the count. Assert the new set is non-empty before diffing: an empty "after" is a failed
measurement, not a recovery.

## 5. When a class turns out to be a real bug

1. Spawn a subagent to reproduce it **with a test** in a worktree on a `<you>/<slug>`
   branch, apply the proposed fix, re-run. It must report CONFIRMED or NOT-REPRODUCED with
   real command output — never a faked pass.
2. If reproduced: create a followup ticket with the description, assign it to yourself, then
   invoke `/work` on it. Pin the tracker's calling convention once and follow it — argument
   order, the rich-text shape a description field demands, which client is read-only — because
   a malformed call here returns an error page that mimics a tracker outage.
3. Record the ticket and the resulting PR in that class's doc section and move Status on.

## 5b. Propose a runbook fix when a class is settled

Once a class is root-caused, the challenge subagent has cleared it, and you are confident in
the steps that actually pinpointed it, file a task proposing the runbook change.

- **Open a task only. Never edit the runbook itself.**
- The task carries the proposed runbook text, ready to paste.
- Write only the steps that LED TO the diagnosis and the fix — not the path you took. Dead
  ends, refuted hypotheses and tool fumbles stay out.
- Style it on the other human-written runbooks: very short, very precise, imperative, a
  numbered list of commands and decision points. Someone under pressure has to read it and
  act in under a minute. Run it through the humanizer skill.
- Re-read and ask: can this be read fast? Prose, a paragraph where a command works, or
  background nobody needs at 3am — rework before filing.
- Link the task from the class section in the doc.

## 6. Write the doc

**One tab per shift** in the shared doc. Tabs are creatable with
`addDocumentTab {tabProperties:{title}}`; every write into one needs `location.tabId` /
`range.tabId`, and each tab has its own index space starting at 1 — never reuse an index
across tabs.

### Brevity — the user asked for this, do not regress

A reference, not a narrative. Per class: what fired, root cause, the evidence that proves
it, the fix. Nothing else.

- BANNED: restating evidence already given; a paragraph where a clause works; cycle-by-
  cycle narration; prose repeating what a link shows; "as noted above"; recapping the
  investigation process.
- A new finding **edits its class section in place**. Never append a dated section.
- The Log is ONE line of semicolon-separated dated entries.
- A quiet cycle adds nothing to the doc.
- **If the doc grows without a new finding, that is a defect.** Re-read before writing and
  cut what the last edit made redundant.
- Root cause = 1-2 sentences. Each evidence bullet = one line, under ~200 chars. A bullet
  needing two clauses of qualification is investigation detail — cut it.

### Section format — same seven elements, same order, every class

```
🔴 <class name>                                       H2, 1pt bottom rule, spaceAbove 22pt
🔴 HIGH · ● ANNOTATED · confidence 9/10 · <id>        status band
┌ annotation box — the 150-350 char paste-as-is text ┐
Fix        one line, options separated by ·
Fired      N× urgency · times with oncall links · lifetime count
Alert      warn/crit · aggregation · sustain · service · def + runbook links
Cause      one or two sentences, the mechanism
Evidence   • one line each; prefix REFUTED / WITHDRAWN / UNVERIFIED inline
```

Field paragraphs use a hanging indent (`indentStart` 92pt, `indentFirstLine` 0) with the
label bold. Sections ordered by severity, not chronology.

**Status band, three coded tokens.** Urgency — `🔴 HIGH` `#b3261e`, `🟡 LOW` `#b06000`;
the highest the class ever reached, not the latest firing. State — `● ANNOTATED` `#1e7b34`
· `● INVESTIGATING` `#b06000` · `● OPEN` `#b3261e` · `● BLOCKED` `#5f6368`. Then
confidence, bold `#1e7b34` when ≥8 and bold `#b3261e` when ≤4:

- **9-10** mechanism read from source AND a competing explanation refuted AND a red team's
  objections survived
- **6-8** mechanism confirmed from source, no red-team pass or one live alternative
- **3-5** correlation only, no mechanism
- **1-2** hypothesis, or the evidence path is blocked

### The annotation block

Every investigated class carries one, written in the same edit that adds the class: plain
text, no markdown, single newlines, 150-350 chars — first line what it is, then the root
cause, then `Fix:` or a ticket. Copy-pasteable into the dashboard as-is.

Style it with a `docs` batchUpdate after every `gdoc_write`, or markdown renders it as body
text and it disappears into the page. Find its paragraphs by matching their text, then
`updateParagraphStyle` shading `#f4f6f8`, indentStart/End 18pt, spaceAbove/Below 0,
lineSpacing 115, borderLeft 3pt `#738cad` padding 8pt; `updateTextStyle` Roboto Mono 9.5pt,
foreground `#212630`.

Slack the annotation recommendations once a class reaches high confidence. Say which are
high confidence and which are inference. Never post one to the dashboard.

### Proving you did not strip an existing annotation

Never verify with a total across annotations. An annotation that loses its last alert drops
its `alerts` key and vanishes from the set you are summing, so the total rises by exactly
what you added while another was emptied. Account instead: list every firing of the affected
def over the whole window, map each id to its owning annotation in the rotation listing, and
confirm the pre-existing annotations still hold their original counts. Take the rotation
snapshot **before** the first attach — one taken afterwards cannot clear earlier calls.

### Once a class is annotated on the dashboard

In the same edit: move the section to the annotated tab, retitle it
`<name> · ANNOTATED, closed`, replace the body with ONE struck line — the detail now lives
in the posted annotation — and keep the annotation box below it. Strikethrough via
`updateTextStyle {strikethrough:true, foregroundColor:"#737880"}` over the heading and the
summary line, never over the annotation box. Do the text appends for every heading first,
then re-read and apply all strikethroughs in one batch: appending shifts every later index.

Google's API cannot collapse headings (`paragraphStyle.collapsed` is rejected). The one
struck line is the substitute. The doc is PAGELESS with 36pt margins — re-check after any
full rewrite.

### Google Docs API traps

- **`gdoc_replace_text` takes `replace_with_text`, NOT `replace_text`.** A wrong field name
  still reports "Replaced 1 occurrence(s)" and **silently deletes** the matched text. Never
  probe with find==replace; verify the schema, then re-read the doc after any replace.
- **`gdoc_replace_text` spans every tab.** Anchor on text unique to the target tab and
  check the reported occurrence count — a shift header that reads the same in two tabs will
  be rewritten in both.
- It matches RENDERED text: no `* ` list markers, no `**` bold. It silently fails on any
  `find_text` containing `…` (U+2026), reporting "Replaced 0 occurrence".
- It inserts into the REPLACED paragraph's style — anchoring on an H2 makes every inserted
  line H2. Fix in the same cycle with `updateParagraphStyle` back to NORMAL_TEXT.
- **The Google Docs MCP server is `google-mcp`.** `google-docs` returns
  `HTTP 404: Service 'google-docs' not found`, which reads like an outage rather than a typo.
- The `docs` tool wants the document id under `params`, not top level:
  `{"resource":"documents","method":"batchUpdate","params":{"documentId":"…"},"body":{…}}`.
- `gdoc_read` returns PLAIN TEXT (body plus an indexed structure dump) for all tabs — do
  not pipe it through `jq`. Verify an insert by re-reading, never by grepping a truncated
  response.
- **Styling does NOT survive `insertText`.** Insert the text, then re-apply headings, body
  style, bullets, bolds and links in a second batch. Compute every offset in **UTF-16 code
  units** — an emoji is 2, not 1 (`len(s.encode('utf-16-le'))//2`). Building ranges from
  Python character offsets bolds the wrong characters.
- **Keep any local markdown source in sync with in-place doc edits**, or the next full
  rewrite silently reverts them.
- **`fields` is a sibling of `textStyle`, not a member.**
  `{"updateTextStyle":{"range":…,"textStyle":{…},"fields":"foregroundColor,bold"}}`. Putting it
  inside `textStyle` fails with a `BadRequest` whose only named field is `requests`.
- **Audit bullet lengths as part of this step**, not as later cleanup — `gdoc_read`, then
  `awk '{print length": "substr($0,1,70)}'`. Eleven bullets had drifted past the ~200 char rule
  before anyone looked.

## 7. Refresh the rolling DM

Update the single Slack status message in place — never post a new one:
`slack_update_message {channel_id:<id>, timestamp:<ts>, message:"…"}`. Keep the timestamp
in the cron prompt and in the loop README; if a new message ever has to be posted, replace
it there.

Under ~12 short lines, telegraphic, no prose paragraphs, no preamble, no sign-off:

```
*<Rotation> watch* · <date time>Z · <N> firings, <M> classes · <state>
<doc link>
• one bullet per finding, ≤10 words each
Annotations: <status>
Open: <ids and ages>
```

Slack is the index; the doc holds the detail. **Never write a `:NN+NN:` pattern** — Slack
renders the colon-delimited span as an emoji shortcode and eats the text. Write "15:03 and
20:07" as prose.

## 8. Close the cycle

Update `seen_alerts.txt` and `deferred_low_open.txt`, append what you learned to the loop
README, then run `/learn`.

### Shift rollover

Shifts run Monday 07:00Z to Monday 07:00Z. Archive `seen_alerts.txt` and `known_defs.txt`
as `*.shift-<date>.txt` and reset; point `WIN_FROM`/`WIN_TO` at the new window; add a new
doc tab; re-create the cron job with the new ids. Resolve a shift id from any alert's
`batchlookupalertcontext` (`shifts[].id`) — `getshift` rejects `rotation_id`, and
`listrotationshiftdates` needs full RFC3339 dates and returns no oncall name.

---

## Proof links

```
logs    <logs-host>/services/<svc>/logs?q=<urlencoded query>&from=<ISO .000Z>&until=<ISO .000Z>
metric  <metrics-host>/query?from=<ISO>&q=<urlencoded query>&until=<ISO>
code    <code-search-host>/<repo>/-/blob/<path>?L<start>-<end>
```

Encode with `jq -rn --arg s "$Q" '$s|@uri'`. Add `| @table:<field>` to a logs link so it
renders the breakdown the claim rests on. Paste an alert's own query verbatim into a metric
link. **Verify a code range at HEAD with the code-search read-file call before citing it** — a local
checkout can lag `origin/main` by weeks and its line numbers differ. Insert the anchor text
first, then attach the URL with an `updateTextStyle` batchUpdate (`fields:"link"`). State
the sample size, and say when a result was truncated at a row cap.

## Querying

**Logs.** The logging MCP's synchronous lucene query. Pin the exact argument shapes once —
they bite: a namespace field that is a LIST not a string, an enum with two legal values, and
times in **epoch milliseconds** (a year-stale epoch returns an empty result with no error).
An async/batch query path is usually rejected for windows inside hot retention, so for recent
data the synchronous call is the only path.

**Metrics.** The metrics MCP's query tool. Read the response shape once and pin it — series
values often arrive under a different key than the obvious one — and note which tag-lookup
call wants the tag name versus the service name.

### Traps that have each cost a cycle

- **A truncated log phrase returns ZERO rows.** `message:` is not phrase-prefix matched —
  read the exact string out of the source (`grep -n 'logger\.\(Info\|Warn\|Error\)('`) and
  query that. No wildcards on `objectType` either; take the exact value from a control.
- **An empty result is not evidence.** Run a control query known to return rows, in the same
  window, immediately before AND after any empty result you intend to rely on.
- **Build every timestamp with shell substitution, never by typing it.** `NOW=$(date -u +%H:%MZ)`
  inside the same call that writes the stamp. Reading the clock and typing the stamp are two acts,
  and a literal composed before the `date -u` in the same command is already stale — this put a
  future time into the doc three times. A cycle runs 25-40 minutes, so a clock read at its start is
  useless by the time anything is written.
  Also run it before choosing any query window: a window in the FUTURE returns empty and is
  indistinguishable from a dead emitter,
  and the usual per-namespace control does not catch it because the control window is in the past.
  The assumed time drifts across a long session. When several UNRELATED series appear to stop at
  the same instant — different metrics, especially different services — suspect the clock or the
  pipeline, never the service; a fleet-wide stop is not a plausible single-team finding.
- **Write "as of the latest emission at HH:MM:SSZ", not "currently."** They differ by up to one
  emission interval even when the clock is right.
- **Logging outages are PER-NAMESPACE**, not backend-wide. Keep one known-good control per
  namespace and run the matching one. Some namespaces return empty
  *non-deterministically* — one namespace gave 0, then 100, then 0 — so there, only a
  non-empty result is evidence. **Never conclude "X does not occur" from an empty result.**
- **A field-scoped zero needs `field:*` probed first**, or it may be a dead query.
- **Filtering on a status field hides an object that changed status.** Query without the
  filter, then group by it.
- **A row cap looks like a small result set.** If distinct ids ≈ the limit, you are capped.
- **Reconcile the metric total against the log total before trusting either.** A count that appears
  in the metric with no matching log rows may be a population the code never logs — one stuck-state
  checker returned early for unmanaged deployments, before its `logger.Warn`. That is an answer, not
  a failed query, and no log filter will ever recover it.
- **Prove a population with the EXCLUSION query, never the inclusion one.** "Show me the X" hits the
  cap and proves nothing about the remainder. Query for everything that is NOT X: a handful of rows
  is under the cap and therefore complete. Pair it with a positive control on the same field so a
  tiny result is not just a broken filter.
- **Check which tags a metric actually carries before crossing two dimensions.** Sibling gauges can
  each carry one and neither carry both, so the crosstab is impossible from metrics and only the log
  line has it — and their totals will differ by exactly the dimension the other one filters on.
- **Do not interleave other gateway queries with a running sweep.** They come back `HTTP 429`, and
  a retry can return 0 rows with no error — indistinguishable from an exhausted result set. Wait
  for the sweep, or treat anything empty measured during one as void.
- **M3 can answer partially and say so.** Check for `partial_read` and retention warnings, and
  count how many zones actually returned series. A negative built on an understated read is not a
  clean negative — label it.
- **One detector tick can be one pod's slice.** Group by `hostname` before quoting a total.
- **A raw log-row count is not a count.** Aggregate over the whole set and say what over.
- **On a ratio alert, measure the DENOMINATOR before judging severity.** A suite running 20-34 times
  a day on a 1d moving rate puts a single failure exactly on a warn line of 97 — the alert is
  reporting one test failure, not a broken suite. Check the raw failure counter, and check whether
  the def's `sum` already aggregates zones before assuming a larger denominator dilutes it.
- **Quote the value the def's own query returns at the resolution you sampled.** Reading percentages
  off a downsampled series produced "97.0 then 96.9" for a series that actually jumps 100 → 96.9697
  → 96.875 and never touches 97.0.
- **Alert sustain shifts the evidence window** — query `fire − sustain − moving_window`.
- **Re-notification is not recurrence.** Count firings and threshold exceedances separately.
- **Before reporting a drop in a steady condition**, check whether the measurement window or
  grouping changed shape rather than the world.
- **When an argument turns on a cadence, compute the distribution — min, median, p90, max — over
  the whole window.** Two observed gaps are not a cadence, and the median alone hides the tail the
  argument depends on. A `keepLastValue` claim in particular is decided by the MAX gap, not the
  typical one: if the horizon exceeds the largest observed gap, the alert always clears on the next
  emission instead.
- **zsh does not word-split an unquoted variable.** `for u in $DEFS` iterates ONCE with the
  whole string; use `${=DEFS}` or an array, and assert every per-def output file exists
  before diffing — a silently missing file reads exactly like a resolved alert.

### More traps that fake a negative result

**Two tag cohorts of one metric: reconcile each, never compare magnitudes.** One test suite's counters exist
under `skipped=false` and under no `skipped` tag; the untagged values are larger, which is NOT
containment. Each cohort independently satisfies `fail + success = total`, so they are disjoint and
`| sum name` across both is right. Reconciliation is the test; magnitude is not. Getting this
backwards published two different wrong success-rate sets in one shift. Companion traps: `run_all` is
an umbrella action mirroring the failing child flow, so never count it beside the children; and an
absent `.success` series is only "zero successes" when `.total` is present and equals `.fail`.

**A suite success rate is an aggregation, not a health reading.** An umbrella action fails whenever
ANY child flow fails, so 0% suite success can coexist with most flows passing — on 09-05 staging
`run_all` read 0% for 09-01 while `global-blast` alone passed 49 of 79 that day. Pair every
suite-level rate with per-flow and per-action rates before describing severity, and say which level
each number came from.

**Use latency counters to tell a fast failure from a timeout.** The ctf action timer stops in a
deferred func (`testing.go:705`), so `.latency` includes failures. Summed latency over `.total`, with
successes credited ZERO time, gives an upper bound on failure duration — enough to rule a retry or
deadline path in or out without any log. Fix the unit first from an action whose duration you know.
State such findings as a bound ("even crediting successes zero time, under 7.5s") rather than a point
estimate; a bound needs no assumption and survives the challenge pass.

**Date every candidate cause before blaming it.** Bisect when the signal STARTED and compare that to
when the symptom started; a cause that postdates the symptom is excluded outright. On 09-05 an
undefined-feature error log in staging looked causal until bisection dated it after the suite was
already failing. The zero side of a bisection needs its own control (a window returning rows, just
not these rows) before it counts as evidence.

**A zero row count is evidence only when the query is far from the row cap.** 0 rows with a green
control on both sides is genuine absence; 100 rows is a truncation that proves nothing about what is
missing. Filter hard enough (add `level:error`) that the answer lands well under the cap instead of
reading absence out of a capped, mixed-level sample. And exonerate positively: pair the zero with a
non-zero count for the same subject ("no error rows, but 71 info rows for the same objects"), which
shows the service is logging about it and has nothing bad to say.

**Probe `field:*` before trusting any field-scoped zero.** Field names are per-namespace: a service
indexes `object_type`, another service indexes `objectType` and has no `object_type` at all. A
field-scoped query against a namespace lacking the field returns 0 rows with no error — identical to
"nothing matched". Run `field:*` first; 0 there means the field does not exist and every query built
on it is void. `.data[0]|keys` gives the real field list for that namespace.

**To see past a row cap, exclude the dominant messages.** A capped query returns whatever the noisiest
message is; chaining `AND NOT message:"<noisy>"` for each one drains the cap until only rare messages
remain. Zero rows after excluding a known-benign set is a far stronger exoneration than "none in the
first 100" — it says the service emits nothing else about that subject at all.

**Trace the call path in source before proposing a mechanism.** Plausible-sounding branches are often
unreachable for the specific inputs in play — a cleanup path that sets `Deleted: changes == nil` skips
the whole bundle-build precheck, so any theory resting on that precheck is dead before it is written.
Two code-search read-file calls settle it. Record each dead branch as one EXCLUDED bullet with its source
link: that is a finding, it stops the next person repeating the trip, and it keeps unverified
mechanisms out of the doc.

**A missing local grep hit means the checkout is stale, not that the symbol is absent.** Search HEAD
with `code-mcp sg_search '{"query":"repo:<repo> func <Name>"}'` before concluding anything from an
empty local grep during a source trace.

**Test a candidate cause against a second FAILING window, not just failing-vs-clean.** A signal that
is high in one bad window and near-zero in another bad window is excluded. Generic yarpc inbound
errors read as causal at 34 per 15 min on one failing day and 1 in the same window on the next, with
the symptom unchanged — failing-vs-clean alone would have confirmed a non-cause.

**A 30-minute loop breeds recent-window bias — compute the distribution before calling anything a
record.** An alert's open interval looked like the longest of the shift at 4h05m because the last few
cycles had seen 2-4h; across the whole shift its resolved durations reached 25.4h. Derive min/max from
the def's own firing history before writing "longest", "worst" or "unprecedented" anywhere.

**Re-measure open classes periodically; a written claim ages into being wrong.** A bullet reading "the
set accumulates and nothing leaves it" stayed in the doc while the set sat flat for 15 hours — the
number was refreshed but the verb was not. Fix the claim, not just the figure. Re-measurement is also
cheap evidence: sampling the same quantity hours apart caught the same 9 items reported under two
different `runtime_env` labels, confirming the env-tag root cause the class had only argued for.

**Know a periodic job's tick interval before choosing a log window.** A 5-minute window against a job
that ticks every ~12 minutes returns 0 rows and reads as "the condition cleared". Widen past one full
period, then filter to a SINGLE tick timestamp before counting — otherwise the same objects are
counted once per tick in the window.

**Enumerate a namespace's real message vocabulary before querying for a specific string.** A guessed
message that does not exist returns 0 with no error, which reads as "the event did not happen". Pull a
short window and chain `AND NOT message:"<dominant>"` to list what the service actually logs, then
query those strings.

**When throughput moves, raw counts mislead — report rates.** A step failing 14 times one day and 47
the next looks like mild growth; against totals of 1302 and 136 it is 1.1% climbing to 34.6%. Always
divide by the matching `.total` series, and say so when the denominator is itself collapsing, because
that collapse is usually a second symptom worth naming.

**Pull latency with fail/total from the first cycle — it is a first-class discriminator.** A class was
chased through error logs for six cycles; `.latency / .total` per action settled it in one call:
validate-config averaged 0.2s on the single clean day and 71-94s on every failing day, while a
neighbouring step stayed flat at 1-6s. That named the failing step and explained a tenfold throughput
collapse at the same time. When a step's latency jumps to tens of seconds, read its source for a retry
policy before theorising — a flat 1-minute backoff over 5 attempts produces exactly that shape.

**Suspect the consumer, not only the producer.** When a verification step fails, query the verifying
service's own namespace and the client library inside it — a subscriber that logs a parse error and
`continue`s drops the update silently, and nothing appears in the producer's logs at all. Rank
candidate signals by whether they are ABSENT on a known-good window with a green control, not by
whether they are elevated on bad ones; "elevated on bad days" survived three false candidates,
"absent on the clean day" did not.

**Dump a log row's keys at the level you care about before saying the detail is absent.** Parse-error
rows were dismissed as carrying only the message; the ERROR rows in that namespace had an `error`
field with the full failure text, which pinned the defect immediately. Field sets differ by level
within one namespace, so `jq -c '.data[0]|keys'` on an actual ERROR row, not an INFO one.

**Scope every defect on two axes before reporting impact: the same component in other environments,
and other components in the same environment.** A staging-only, one-client defect reads very
differently from a shared-library bug. Crucially, "absent in production" is only evidence when the
component demonstrably runs in production — check for its rows there first, or the absence is just
missing coverage.

**Match the SHAPE of candidate and symptom before promoting a candidate.** Clean-day absence is
necessary but not sufficient: a candidate that fires in bursts cannot explain a symptom that occurs at
a steady rate every hour. Pull both at hourly resolution over the same day and compare shapes — one
such comparison refuted a candidate that had already been written up as leading. Conversely, a steady
symptom rate is itself a clue: it points at something continuous, not episodic.

**A difference between two cohorts is a lead only if the DIFFERENCE is new.** One metric cohort
failing 5-10x more than another looks decisive until the same ratio shows up on a known-good day.
Compute the cohort ratio on a clean day first; if it holds there, the asymmetry is structural and the
change you are chasing is elsewhere — check instead whether both cohorts moved together.

**Search Jira for the exact error string early — then verify the hit against HEAD.** A closed ticket
naming the same symptom is a pointer to the right code, not an explanation: one such ticket blamed a
provider that demonstrably sets the missing field at HEAD, so the current occurrence has a different
source. Cite the prior ticket AND the check that ruled its attribution in or out.

**Sweep Jira prior art across every open class at once.** Precedent search is cheap and finds owners,
past mitigations and known shapes; running it only on the class currently in focus leaves the others
uninformed for days. When a hit arrives, check the alert UUID it cites against the def you are
investigating — a ticket with the same symptom name can belong to a sibling alert (staging vs global),
in which case its conclusions do not transfer.

**Look for a reason/detail field before inferring which code branch fired.** A detector that logs
`stuck_reason` states the condition, age and threshold in words, naming the branch directly — an
inferred attribution had been wrong for days in exactly the inverse direction. When such a correction
lands, re-check every downstream claim built on the old attribution; one of them will usually fall too.

**A reason string is a summary; read the predicate's skip clauses.** "All targets are terminal" turned
out to skip NotStarted targets entirely, so it actually meant "no target in flight" — which covers
both a finished plan awaiting closure and a rollout that stalled before starting its remaining zones.
Trusting the wording would have kept a wrong interpretation in the doc. Read the loop, note what it
`continue`s past, and say which readings the evidence cannot separate.

**Re-test a "data is unavailable" assumption before building around it.** A note that flight-plan state
purges too fast had been taken as given for two cycles; one call returned complete state for every
plan and settled the open question immediately. Where an object has `created_at` and `updated_at`,
their delta is the cheapest stalled-vs-finished discriminator available — a record created and last
touched two seconds later, then silent for a day, stalled; it did not finish.

**`updated_at` measures writes to a record, not progress of the work.** A plan whose state row stopped
updating two seconds after creation was still starting targets seconds later — the timestamp had
frozen while the work continued. Establish a stall from the executing component's own log lines
(executor start, per-target start/terminal), and treat a timestamp column as corroboration at best.

**Exclude the polling vocabulary to find where a workflow stopped.** Status-poll lines dominate any
long-running execution's logs and hide the transitions. Chain `AND NOT message:"<poll line>"` for each
one; what remains is the state machine's actual narrative — in one case two `signal continue`
transitions followed by nothing, which located the stall exactly. Pair it with the plan's declared
step structure so the shortfall is described in steps, not raw target counts.

**Break an aggregate down by its obvious categorical field before characterising it.** A set of 8
stuck items looked like one failure mode from a single sample; grouped by action type it was three
distinct modes, each perfectly consistent within its group, and two competing readings that had been
argued over for cycles turned out to be describing different groups. Enumerating a small set costs a
few calls and beats any amount of reasoning from one member.

**Resolve an identifier to its owning component before claiming two classes are connected.** Two sets
of objects both named "...test..." are not thereby related: one `sg_search` on the literal resource-id
prefix found the fixture file that mints them and showed they belong to different test suites in
different packages. A link asserted on name similarity survived two cycles and was wrong. When such a
link is withdrawn, explicitly downgrade any timing coincidence that was resting on it.

**Summary fields accrete; measure them periodically.** Root cause and Fix attract one clause per
cycle and quietly become restatements of the evidence bullets — one had reached 1108 characters
against a 1-2 sentence target. Compute paragraph lengths from the structure dump every few cycles and
cut the summary back to its claim, leaving detail in the bullets that already carry proof links. Do
the same sweep for claims orphaned by a withdrawn premise.

**Verify a documented mitigation actually executes before repeating it.** A prior ticket cleared the
same alert by aborting the stuck objects; on the current plans the abort was recorded and did
nothing — no target-level execution followed either the rollback or the abort, and the plans stayed
in their original state. Check for the work the mitigation should have caused, not the log line that
says it was requested.

**Promote a def into the persistent union list in the same cycle the sweep first reports it.** The
sweep is unstable in both directions: a def that fired can vanish from the next sweep entirely. On
09-07 that would have turned a shift with an open HIGH alert into a "0 firings" report, because the
newly-seen def had not yet been added to the union queried every cycle. Append on sight, then diff.

**Per-step attribution comes from action-level counters, not from the warehouse.** For any
blackbox/synthetic suite, the per-ACTION counters (`fail`/`success`/`total`/`latency` per
distribute, teardown, validate, wait…) say which STEP failed; flow-level counters only say
which flow did. Try them before queueing an async warehouse query — one such query sat
unstarted for 80+ minutes while a single metric call answered the question. A step's `fail`
of zero exonerates that step only when its `total` is non-zero.

**Consolidate exclusions.** As a trace rules out branches, fold them into ONE bullet per
class naming each dead branch with its `file:line`, rather than appending a bullet per
branch. The section stays flat and the next investigator still sees every trip taken.

