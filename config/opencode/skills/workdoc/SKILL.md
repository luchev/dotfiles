---
name: workdoc
description: Save or update progress in a shared running work log stored as a Google doc. Use whenever progress should survive losing the session — at phase boundaries, before a long or risky operation, after something lands — and whenever the user says "save progress", "update the workdoc", "log this", or "write this down". Also use to add or tick Open items.
---

# /workdoc — save progress to the running task log

One Google doc holds a running log of every task. Structure, top to bottom: `Open items`,
then one `## <heading>` section per task, **newest first**, separated by horizontal rules.

## Configuration

The doc id lives in `~/.config/workdoc/config`, not in this file:

```bash
CONF=~/.config/workdoc/config
[ -f "$CONF" ] || { mkdir -p "$(dirname "$CONF")"; printf 'DOC_ID=\nTICKET_URL=\n' > "$CONF"; }
. "$CONF"
```

- `DOC_ID` — the id in `https://docs.google.com/document/d/<DOC_ID>/edit`.
- `TICKET_URL` — issue-tracker browse prefix, e.g. `https://jira.example.com/browse/`.
  Optional; omit the **Issue:** line when unset.

If `DOC_ID` is empty, ask the user for the doc once and write it to the config. Never
guess a doc id, and never create a new doc to "fix" a missing one.

Writes go through whatever Google Docs MCP is configured — the calls below are named for
the common one (`gdoc_read`, `gdoc_write`, `gdoc_delete_range`, plus a raw `documents.
batchUpdate` escape hatch). Adapt the invocation to the local MCP client; the semantics,
not the spelling, are what matters.

## When to run it

The point is that a killed session or a rebooted machine loses nothing. Save at:

- the end of a phase (research done, plan agreed, implementation green)
- **before** anything long or risky — a big fetch, a rebase, repo surgery, a stress run
- after a change is published, lands, or a ticket changes state
- whenever the user asks

Cheap and idempotent — re-running updates the existing section rather than adding a
second one. Prefer saving too often over too rarely.

## Step 0: read the current doc

Always read before writing. Other sessions write here too.

Download the doc (any Docs export path works) and note **every** section heading that
exists. If a section you wrote earlier has vanished, someone overwrote it — restore it in
the same write rather than leaving it lost.

## Step 1: decide update-in-place or new section

- **Section for this task exists** → replace its body (Step 3).
- **No section** → insert a new one directly above the current top section (Step 4).

Never rewrite the whole document. A full-body write reports success either way and
silently destroys concurrent edits — one destroyed a just-written entry on 2026-09-04.
This skill never uses a whole-document write.

## Step 2: get UTF-16 indices

```
gdoc_read {document_id: <DOC_ID>}
```

Every paragraph prints as `N. [start:end] STYLE: "text" [paragraph_style=…]`. You need
these numbers — the write API is index-addressed, not text-addressed.

## Step 3: replace an existing section

Delete from the section's heading start index up to (not including) the next section's
heading start index, then insert the new body at the same place per Step 4.

```
gdoc_delete_range {document_id: <DOC_ID>, start_index: A, end_index: B}
```

Deleting a range that ends at the next heading also consumes the blank paragraph before
it. Re-read after deleting to pick a fresh anchor — never reuse the pre-delete index.

## Step 4: insert

```
gdoc_write {document_id: <DOC_ID>, index: N, markdown: true, mode: "insert",
            content: "\n## **Title**\n\n**Status:** …\n\n* ☑ done\n* ☐ todo\n"}
```

Four rules, each learned the hard way:

1. **There is no dry run.** Passing one is ignored and the write happens. There is no
   preview — get the index right first.
2. **Inserted text inherits the paragraph style at `index`.** Anchoring at the start of a
   `HEADING_2` paragraph turns every inserted line into a heading. Anchor at an index
   **inside a `NORMAL_TEXT` paragraph** and prefix the content with `\n`.
3. **Bare URLs are dropped silently.** Always `[text](url)`. Verify links survived.
4. **Anchoring inside a paragraph merges your first line into it.** Insert a bare `\n`
   first to split it, then repair the paragraph style of the split-off half.

Setting a paragraph style does not set bold. Match bold headings with a raw text-style
update:

```
documents.batchUpdate {documentId: <DOC_ID>, requests: [{updateTextStyle: {
  range: {startIndex: S, endIndex: E}, textStyle: {bold: true}, fields: "bold"}}]}
```

## Step 5: Open items

Open items live in their own section at the top as `☐` lines. Add one per thing that needs
a human or a later trigger. Tick to `☑` — or delete the line — when it is done. One line
each, and name the ticket.

## Step 6: verify

Re-read (Step 0) and confirm: your section is present at the right heading level, links
resolve, and **no other section disappeared**. A write that reports success can still have
landed with the wrong styles.

## Entry format

Match the surrounding sections:

```markdown
## **<TICKET> — <short title>**

**Status:** <one line: where it actually stands>

**Issue:** [<TICKET>](<TICKET_URL><TICKET>)

**Change:** [#<N>](<link>) — <state>

<1-3 sentences of context: the problem, not the narrative.>

* ☑ <done>
* ☐ <outstanding>

**Notes:** <non-obvious findings a future session would otherwise rediscover.>
```

Terse. Conclusions, not transcripts. No tables — they do not render in Google Docs.

## Autonomous mode

`/loop-update-workdoc` is a cron loop that watches recent coding-agent sessions and folds
them into this doc on its own, using the write path above. This skill stays the manual,
single-entry path.
