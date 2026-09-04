---
name: loop-watch-reviews
description: >
  Recurring loop that tracks PRs awaiting your review, reviews each one WITHOUT
  posting anything to GitHub or Slack channels, records verdicts in a Google doc,
  drops entries once the PR is gone, and DMs you a short "you can review these N
  PRs" summary. Use when the user says "watch my review queue", "loop watch reviews",
  "keep track of PRs to review", or "start the review loop".
allowed-tools: Bash, Read, Write, Edit, Agent, CronCreate, CronList, CronDelete, mcp__omni-mcp__invoke_tool
---

# /loop-watch-reviews — Review Queue Watch Loop

A 30-minute cron loop. Each cycle: collect PRs awaiting your review, review the
new or changed ones, keep a Google doc current, and refresh one rolling Slack DM.

## Hard rules — read every cycle

- **Never write to GitHub.** No review comments, no inline comments, no approvals,
  no labels, no merges. Reading is the only GitHub write-side interaction allowed.
- **Never post to `#ucsd-review-queue`.** No `!wdone`, no `!wadd`, no replies. The
  user marks items done themselves.
- **The Slack DM is one rolling message**, updated in place — never a new post.
- **A verdict must be defensible.** If you did not read the diff with context, the
  verdict is `Unreviewed`, not `Clean`.
- Removing a PR from the doc happens **only** when it is merged, closed, or the
  user says they reviewed it. Never because the loop lost track of it.

## State

`~/.claude/loop-watch-reviews/`

| File | Contents |
|---|---|
| `README.md` | doc id, Slack DM channel + rolling message ts, team author list |
| `tracked.tsv` | `pr_id<TAB>head_sha<TAB>verdict<TAB>reviewed_at<TAB>diff_hash` — one row per PR in the doc. `diff_hash` is `gh pr diff <N> \| sha256sum`, so a rebase can be told apart from a real change |
| `dropped.txt` | pr ids removed from the doc, so they are not re-added |

`pr_id` is `<owner>/<repo>/<number>` for GitHub, or the bare `D<number>` for Phabricator.

`head_sha` is why a PR gets re-reviewed: if the head moved since `reviewed_at`,
the old verdict is stale and the PR goes back in the review set.

---

## Bootstrap (first run only)

Skip everything here if `~/.claude/loop-watch-reviews/README.md` already exists.

1. Resolve the Slack DM: `slack-mcp` → `slack_lookup_by_email {email}` for the
   user. DM channel for `luchev@uber.com` is `D01PM28SFB5`.
2. Create the Google doc: `cd` to the google-workspace skill dir, then
   `python3 scripts/write_docs.py --create "PR review watch — <team>" /tmp/review-doc.md`.
   PAGELESS is not reachable from these scripts — do not try.
3. Post the rolling Slack message once (`slack_send_message`), keep its
   `message_ts`.
4. Write `README.md` with the doc id, DM channel id, rolling ts, and the team
   author list. Seed the list from `#ucsd-review-queue` participants and confirm
   it with the user before the first sweep — as of 2026-09-03: `bos`,
   `michael.jaquier`, `kshitij.suri`, `stefan.hahn`.
5. Schedule the cron — pick an off-minute, not `:00`/`:30`:

   ```
   CronCreate {cron: "13,43 * * * *", recurring: true,
               prompt: "/loop-watch-reviews cycle"}
   ```

   Tell the user the job is session-only and auto-expires after 7 days.

---

## Cycle

### Step 1 — Collect the candidate set

Three sources, queried **in parallel**. Union them, dedupe on `pr_id`.

**a. BMO WorkQueue in `#ucsd-review-queue`** (channel `C0BCJSFNHM0`)

Read the channel and find the most recent BMO reply to a `!w`:

```
slack-mcp → slack_read_channel {channel_id:"C0BCJSFNHM0", limit:50, response_format:"concise"}
slack-mcp → slack_read_thread  {channel_id:"C0BCJSFNHM0", message_ts:"<ts of latest !w>"}
```

That reply lists the queue with owner and size. **Reconstruct forward from it**:
apply every `!wadd` / `!wdone` / BMO "removed from the Work Queue" message posted
*after* that `!w`. A stale `!w` snapshot alone is wrong — an item done two minutes
later still shows in it.

Never post `!w` yourself to refresh the snapshot.

**b. GitHub review-requested**

```bash
gh search prs --review-requested=@me --state=open --json repository,number,title,author,updatedAt
```

**c. Team-authored open PRs**

```bash
gh search prs --repo=uber-code/go-code --state=open --author=<a> --json number,title,author,updatedAt
```

for each author in `README.md`'s team list. Cap at PRs updated in the last 14 days.

Exclude from the candidate set: PRs authored by the user, drafts, and anything in
`dropped.txt`. **A draft that was explicitly `!wadd`ed to the queue is NOT excluded** —
the author asked for review, and that outranks the draft flag. Say in the doc and the
DM that it is still a draft.

Stacked PRs: read `baseRefName` on every candidate. When a base is another PR's branch
rather than `main`, work out the whole chain and pass the stack order to each reviewer —
a subagent diffing against `main` will attribute every parent's change to the child.

### Step 2 — Diff against state

For each candidate, fetch head sha and state:

```bash
gh pr view <N> --repo <owner>/<repo> --json state,isDraft,headRefOid,title,author,additions,deletions,url
```

Partition:

- **Gone** — `state` is `MERGED` or `CLOSED`, and it is in `tracked.tsv` → remove
  its section from the doc, append to `dropped.txt`, drop the row.
  (Landed Uber PRs show `CLOSED`; treat closed and merged the same for removal.)
- **New** — not in `tracked.tsv` → review.
- **Stale** — in `tracked.tsv` but `headRefOid` differs from the stored sha → **check
  whether the content actually changed before re-reviewing**. A rebase moves the head
  without touching the PR's own diff. Compare `sha256` of `gh pr diff <N>` against the
  stored `diff_hash`: if it matches, this is a rebase — carry the verdict forward, update
  `head_sha` and `diff_hash`, and do NOT spawn a reviewer. Only a changed diff hash is a
  real re-review.
- **Unchanged** — carry the existing verdict, do no work.

If nothing is new, stale, or gone: **quiet cycle**. Touch neither the doc nor
Slack. Say so in one line and stop.

### Step 3 — Review the new and stale PRs

One `Agent` subagent per PR, `subagent_type: general-purpose`, spawned **in one
message so they run concurrently**. **Spot-check every verdict yourself** before it
reaches the doc — a `Blocking` claim against the head SHA, and for a `Clean` on a
metrics or config change the one thing that class of change usually gets wrong
(tag cardinality; whether every setting survived a move). A subagent verdict you
did not check is not evidence. Model by size: `haiku` under ~50 changed
lines, `sonnet` otherwise; `opus` only for a diff over ~800 lines.

Each subagent prompt must say:

> Review `<url>` read-only. Do NOT post comments, do NOT approve, do NOT run
> `gh pr review` or any GitHub write command. Check out the PR in a temp worktree
> or use `gh pr diff <N>`. Read the diff with `-U10` context, not just changed
> lines. Follow `~/.claude/skills/review/SKILL.md` for what to look for and the
> repo's `CLAUDE.md` for conventions.
>
> Return exactly:
> - `VERDICT:` one of `Clean` · `Nits` · `Concerns` · `Blocking`
> - `ONE_LINER:` under 12 words, what the PR does
> - `FINDINGS:` bullets, each `file:line — what is wrong`. Empty for Clean.
> - `HEAD_SHA:` the sha you reviewed.
>
> A finding you cannot point at a line for does not go in the list. If the diff
> would not fetch, return `VERDICT: Unreviewed` and say why — never guess.

Verdict taxonomy — keep it strict:

| Verdict | Means |
|---|---|
| `Clean` | Read it fully, nothing to say. Stamp it. |
| `Nits` | Style, naming, comments. Nothing that changes behaviour. |
| `Concerns` | Something you would want answered before stamping. |
| `Blocking` | A correctness, security, or data-loss defect. |
| `Unreviewed` | Could not fetch or could not judge. Say why. |

### Step 4 — Update the Google doc

One section per tracked PR, ordered by verdict severity (`Blocking` → `Concerns`
→ `Nits` → `Clean` → `Unreviewed`), not by age.

```
### <title> · <verdict>
[#<N>](<url>) · `<author>` · +<a>/-<d> · reviewed <sha[:9]> · <relative time>
**What.** <one liner>
**Findings.** <bullets, one line each; omit the block entirely when Clean>
```

Then a single `## Log` line at the bottom: semicolon-separated dated entries.

Brevity rules — the doc is a worklist, not a narrative:

- A re-review **edits the section in place**. Never append a dated block per cycle.
- BANNED: restating the diff, cycle narration, "as noted above", prose that
  repeats what a link shows.
- Removing a merged PR removes its whole section. Add one clause to the Log line.
- **If the doc grows without a new verdict, that is a defect.** Re-read before
  writing and cut what the last edit made redundant.
- Doc writes go through the google-workspace scripts, not raw MCP tools:
  `cd "$(dirname "$(find ~/.local/share/aifx -path '*/google-workspace/skills/google-workspace/SKILL.md' | head -1)")"`
  then `python3 scripts/write_docs.py <doc_id> /tmp/review-doc.md` to replace the
  body, or `scripts/download_docs.py <doc_id>` to read it back. Keep the whole doc
  in one local markdown file, edit that, and rewrite — it is simpler than
  targeted replaces and cannot silently delete a section.
- Markdown tables do not render usefully here. Use the layout above.

### Step 5 — Update the rolling Slack DM

```
slack-mcp → slack_update_message {channel_id:"D01PM28SFB5", timestamp:"<rolling ts>", message:"..."}
```

Conversational and short — this is the message that tells the user what they can
go stamp right now. Under ~10 lines, one line per PR, worst first:

```
*Review queue* · <N> waiting · <doc link>
You can stamp these now:
• <#N> `author` — clean, nothing to say
• <#N> `author` — nits only: naming in foo.go
Worth a look first:
• <#N> `author` — concern: unguarded map write in bar.go:88
• <#N> `author` — blocking: drops the error from Close()
Merged since last cycle: <#N>, <#N>
```

Omit any group that is empty. No preamble, no sign-off.

### Step 6 — Write state back

Rewrite `tracked.tsv` and `dropped.txt`. Then report to the terminal in two or
three lines: how many reviewed, the verdict spread, what dropped.

---

## Stopping

`CronList` to find the job, `CronDelete {id}` to stop it. The state dir and doc
survive; a later run picks up from `tracked.tsv`.
