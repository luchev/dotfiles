---
name: loop-watch-reviews
description: >
  Recurring loop that tracks PRs awaiting your review, reviews each one WITHOUT
  posting anything to GitHub or to a team channel, records verdicts in a shared
  doc, drops entries once the PR is gone, and DMs you a short "you can review
  these N PRs" summary. Writes to a JSON file, the doc, or both (`--sink json|doc|both`).
  Use when the user says "watch my review queue", "loop
  watch reviews", "keep track of PRs to review", or "start the review loop".
---

# /loop-watch-reviews — Review Queue Watch Loop

A cron loop. Each cycle: collect the PRs awaiting your review, review the new or changed
ones, keep a shared doc current, and refresh one rolling DM.

## Hard rules — read every cycle

- **Never write to the code host.** No review comments, no approvals, no labels, no
  merges. Reading is the only write-side interaction allowed.
- **Never post to the team channel.** The user marks items done themselves.
- **The DM is one rolling message**, updated in place — never a new post.
- **A verdict must be defensible.** If you did not read the diff with context, the verdict
  is `Unreviewed`, not `Clean`.
- Removing a PR happens **only** when it is merged, closed, or the user says they reviewed
  it. Never because the loop lost track of it.

## State

A state dir outside any repo, holding:

| File | Contents |
|---|---|
| `README.md` | doc id, DM channel + rolling message ts, team author list |
| `tracked.tsv` | `pr_id<TAB>head_sha<TAB>verdict<TAB>reviewed_at<TAB>diff_hash<TAB>url<TAB>thread` — one row per PR in the doc |
| `dropped.txt` | ids removed from the doc, so they are not re-added |

`diff_hash` is `sha256` of the PR's diff, so a rebase can be told apart from a real
change. `head_sha` is why a PR gets re-reviewed: if the head moved since `reviewed_at`,
the old verdict is stale.


## Output sinks

Two sinks, selected per run: **JSON** (a local file other skills read) and **the doc**.

`--sink json|doc|both` on the invocation wins; otherwise `sink=` in the state dir's `README.md`; otherwise
`both`. A cron prompt that names a sink keeps naming it, so a re-armed job does not drift
back to the default.

| sink | behaviour |
|---|---|
| `json` | write `<state dir>/state.json`. Skip every doc read and doc write. The rolling DM follows the doc, so it is skipped too. |
| `doc` | write the doc as described below. No JSON file is written or updated. |
| `both` | JSON first, then the doc. The default. |

The JSON is the contract other skills depend on, so treat it like one:

- **Rewrite the whole file every cycle**, never append — including a quiet cycle, which
  rewrites an identical `items` with a fresh `generated_at`. Freshness is how a consumer
  tells "nothing changed" from "the loop is dead".
- **Write atomically**: `state.json.tmp` then `mv` into place. A consumer may read
  mid-cycle.
- An item that leaves the set this cycle appears once in `removed[]` with its reason, then
  is gone. Never drop an item silently.
- Under `doc`, do not delete a stale `state.json` — leave it, and let its `generated_at`
  show it is not being maintained.

```json
{
  "schema": "review-watch/1",
  "generated_at": "<ISO 8601 Z>",
  "cycle_started_at": "<ISO 8601 Z>",
  "sink": "json|doc|both",
  "items": [
    {"id": "<pr_id>", "url": "…", "thread": "<url or null>", "title": "…",
     "author": "…", "state": "open|draft", "verdict": "Clean|Nits|Concerns|Blocking|Unreviewed",
     "one_liner": "…", "head_sha": "…", "diff_hash": "…", "reviewed_at": "<ISO>",
     "size": {"logic": {"added": 0, "removed": 0}, "tests": {"added": 0, "removed": 0}},
     "findings": [{"file": "…", "line": 0, "text": "…", "url": "<link pinned at head_sha>"}]}],
  "removed": [{"id": "…", "reason": "…"}]
}
```

`findings[].url` is already pinned at `head_sha`, so a consumer never has to
reconstruct a link. `verdict` is the only field another skill should branch on.

## Cycle

### Step 1 — Collect the candidate set

Query the sources in parallel and union them:

**a. The team's review channel.** Read the messages and **scan every one for PR links** —
in requests, in bot notices, and in plain prose. Do not build the candidate set from a
queue bot's summary alone: a mistyped command never enqueues, the bot's snapshot goes
stale the moment someone marks an item done, and people link PRs in discussion without
ever queueing them. An id already in `tracked.tsv` or `dropped.txt` needs no fetch;
everything else gets its state checked.

If a queue bot is available and the user has given you a thread to use, its live output is
the best signal for **what the user still owes a review** — and often the only one, since
some hosts do not surface the user's own approval through the API at all. A tracked PR
that is still open but has dropped out of that list has been stamped; remove it.

**b. Review-requested search** — `gh search prs --review-requested=@me --state=open`.

**c. Team-authored open PRs** — `gh search prs --repo=<repo> --state=open --author=<a>`
per author in the team list, capped to recently updated ones.

A search that errors is **not** evidence that nothing is new. The per-PR `gh pr view` loop
over `tracked.tsv` is the authoritative check; say which sweeps failed rather than
reporting the cycle quiet on their silence.

Exclude: PRs authored by the user, drafts, and anything in `dropped.txt`. A draft the
author explicitly asked for review on is **not** excluded — say it is a draft.

Stacked PRs: read `baseRefName`. When a base is another PR's branch, work out the chain
and pass the stack order to the reviewer — an agent diffing against `main` will attribute
every parent's change to the child.

### Step 2 — Diff against state

```bash
gh pr view <N> --repo <owner>/<repo> --json state,isDraft,headRefOid,title,author,additions,deletions,url
```

- **Gone** — merged or closed → remove from the doc, append to `dropped.txt`.
- **New** — not tracked → review.
- **Stale** — head moved → compare the diff hash first. If it matches, this was a rebase:
  carry the verdict, update the shas, spawn nothing. Only a changed hash is a re-review.
- **Unchanged** — carry the verdict, do no work.

Nothing new, stale, or gone: **quiet cycle**. Touch neither the doc nor the DM, say so in
one line, stop — the JSON sink still refreshes its `generated_at` (see Output sinks).

### Step 3 — Review

One subagent per PR, spawned in a single message so they run concurrently. Size the model
to the diff. **Spot-check every verdict yourself** — a subagent verdict you did not check
is not evidence.

Each prompt must say:

> Review `<url>` read-only. Do NOT post comments, do NOT approve, do NOT run any write
> command against the code host. Do NOT create branches and do NOT check the PR out into
> the primary checkout — use `gh pr diff <N>` and read base files with
> `git show origin/main:<path>`. Read the diff with `-U10` context, not just changed lines.
>
> Return exactly:
> - `VERDICT:` one of `Clean` · `Nits` · `Concerns` · `Blocking`
> - `ONE_LINER:` under 12 words
> - `FINDINGS:` bullets, each `file:line — what is wrong`. Empty for Clean.
> - `HEAD_SHA:` the sha you reviewed.
>
> A finding you cannot point at a line for does not go in the list. If the diff would not
> fetch, return `VERDICT: Unreviewed` and say why — never guess.

| Verdict | Means |
|---|---|
| `Clean` | Read it fully, nothing to say. Stamp it. |
| `Nits` | Style, naming, comments. Nothing behavioural. |
| `Concerns` | Something you would want answered before stamping. |
| `Blocking` | A correctness, security, or data-loss defect. |
| `Unreviewed` | Could not fetch or could not judge. Say why. |

Two things reviewers routinely get wrong, worth stating in the prompt: an automated
"fix the build" commit can invert test assertions while resolving a rebase, so a green
suite after one proves nothing; and the author's own framing ("just a nit", "small diff")
is a claim to test, not a reason to review shallowly.

### Step 4 — Update the doc

One section per tracked PR, ordered by severity, not age:

```
### <title> · <verdict>
[#<N>](<url>) · `<author>` · +<a>/-<d> · reviewed <sha[:9]> · <when>
**What.** <one liner>
**Findings.** <bullets; omit the block entirely when Clean>
```

Every finding's `file:line` is a **link to that line**, pinned at the SHA you reviewed:
`https://<host>/<owner>/<repo>/blob/<head_sha>/<path>#L<line>` (`#L<a>-L<b>` for a range).
Pin the SHA — a branch link silently drifts to different code. Multiple lines in one file
get one link each rather than a bare comma list, so every claim is one click from its
evidence.

Then a single `## Log` at the bottom, one dated line per cycle.

The doc is a worklist, not a narrative. A re-review **edits its section in place** — never
append a dated block per cycle. Banned: restating the diff, cycle narration, prose that
repeats what a link shows. **If the doc grows without a new verdict, that is a defect.**
Keep the whole doc in one local markdown file, edit that, and rewrite it wholesale —
simpler than targeted replaces, and it cannot silently delete a section. Assert the
section count before publishing.

### Step 5 — Update the rolling DM

Short and conversational — this is what tells the user what to go stamp right now. One
line per PR, worst first:

```
*Review queue* · <N> waiting · <doc link>
You can stamp these now:
• <#N> · <thread> — `author` clean, nothing to say
Worth a look first:
• <#N> · <thread> · <(2)> · logic +9/-12, tests +28/-23 — `author` concern: unguarded map write in bar.go:88
Merged since last cycle: <#N>
```

**Capture the link when you first see the PR, or the summary cannot show one.**
`<thread>` and the PR link are read out of `tracked.tsv`, so both must be written in the
same cycle the row is created — recovering them later means re-fetching every PR. Store the
PR's own URL in `url`, and the discussion thread in `thread` when the review platform has
one. A review platform without threads (a plain diff tool, say) leaves `thread` empty: emit
the bare id and no separator rather than a placeholder, and never invent a link.

Every line carries the PR link and its channel thread, so the discussion is one click from
the verdict. A PR with findings also carries **`(N)`, the finding count, linked to the
doc** — it says at a glance how much is waiting there. Omit `(N)` when the verdict is
Clean; zero remarks needs no marker.

Each line also carries the diff size **split into logic and tests**, so the user can see
what they are walking into before opening anything. Count the diff's own `+`/`-` lines,
classifying by path (`*_test.go`, `**/testutils/**`, and the repo's other test
conventions), not the host's single total:

```bash
gh pr diff <N> --repo <owner>/<repo> | awk '
  /^\+\+\+ b\// { f=substr($0,7); istest = (f ~ /_test\.go$/ || f ~ /\/testutils\//); next }
  /^\+/ && !/^\+\+\+/ { if (istest) ta++; else la++ }
  /^-/  && !/^---/       { if (istest) td++; else ld++ }
  END { printf "logic +%d/-%d, tests +%d/-%d\n", la, ld, ta, td }'
```

The split is itself a review signal, so state it even when it is lopsided: a large
behavioural change with no test movement, or a config flip with no tests at all, is worth
the user seeing before they open the diff. Write `no tests` rather than `tests +0/-0`.
Reconcile the total against `gh pr view --json additions,deletions`; a mismatch means the
classifier missed a path.

Omit empty groups. No preamble, no sign-off.

### Step 6 — Write state back

Rewrite `tracked.tsv` and `dropped.txt`, then report in two or three lines: how many
reviewed, the verdict spread, what dropped.

## Stopping

Find the cron job and delete it. The state dir and doc survive; a later run picks up from
`tracked.tsv`.
