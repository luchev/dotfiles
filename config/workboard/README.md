# Work Board

A private, single-page status board for one person's in-flight work. It answers, in a
two-second glance and without scrolling or clicking: what is blocked on someone else,
is any CI red, is anything on fire, and is the machine healthy. Anything that needs a
click has failed at its job.

Read on a laptop through an SSH tunnel to the box where the work happens, in a browser
tab kept open beside a terminal all day.

## Running it

```sh
./serve.sh          # static server on 127.0.0.1:8777, idempotent — safe as a watchdog
```

```sh
ssh -N -L 8777:127.0.0.1:8777 <box>    # from the laptop, then open 127.0.0.1:8777
```

Bound to loopback only. Never expose it — the feeds contain whatever your work contains.

A cron keeps it up and the data fresh:

```cron
*/7 * * * * bash -lc '$HOME/.claude/dashboard/collect.sh' >/dev/null 2>&1
*/3 * * * * $HOME/.claude/dashboard/serve.sh --quiet >/dev/null 2>&1
@reboot     $HOME/.claude/dashboard/serve.sh --quiet >/dev/null 2>&1
```

## Panels

Blocked on others · Open PRs · Review queue · Oncall alerts · Sprint tickets ·
Background work · Recently landed · Repo and machine health.

## Feeds

`index.html` only reads. Every panel is one file in `data/`, written by something else
— a cron collector, an agent loop, a script of your own. A panel whose file is missing
says so; a panel whose file is old says how old. **Staleness is first-class: stale data
must never be able to masquerade as fresh.**

Each feed is written twice. `data/<name>.json` is the durable contract;
`data/<name>.js` wraps the same bytes in `WB.set("<name>", {…});` because `fetch()`
cannot read a sibling file from a `file://` page, so the board loads feeds as
`<script>` tags instead.

```jsonc
{
  "generated_at": "2026-09-14T08:53:00Z",   // required on every feed — drives staleness
  "items": [ /* shape depends on the panel; see index.html's render() */ ]
}
```

`collect.sh` is deliberately **not** in this repo: what it queries is specific to where
you work. Write your own, or keep a private one and symlink it in beside these files.

Two parsers are included because they are generic — they turn a Markdown export of a
running notes document into `oncall.json` / `reviews.json`:

```sh
./collect-oncall.py     # alert investigations → data/oncall.json
./collect-reviews.py    # PR review verdicts and findings → data/reviews.json
```

Both read the newest `*.md` under `~/Documents/google-workspace/*oncall*/` and
`*review*/` respectively, and expect the section template documented in each file's
docstring.

## Constraints

These are the whole design, not preferences:

- One hand-authored `index.html`. No build step, no bundler, no framework, no CDN.
- Fonts are self-hosted in `fonts/` (all OFL, texts in `fonts/LICENSES/`).
- Must render correctly with any panel's JSON missing or stale — that is the normal case.
- Colour is never the only carrier of state: every status is a word plus a drawn mark.
- Light ground only. The type scale is four steps, each ≥1.25× the last.

## Layout state

Panel widths and column widths are draggable and persist per browser in `localStorage`,
keyed by the panel's stable `data-id`. The age-column typeface has a toggle in the
masthead. None of this is server state — clearing site data resets it to the defaults.
