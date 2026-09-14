---
name: workboard
description: Run, debug, restyle or extend the Work Board — the private single-page status board at ~/.claude/dashboard served on 127.0.0.1:8777. Use when the user says "the board", "work board", "dashboard", asks why it is down, stale or empty, wants a new panel or feed, or wants its type, colour or layout changed. Not for Grafana or any hosted dashboard product.
---

# Work Board

A hand-authored single-page board answering, in a two-second glance: what is blocked on
someone else, is any CI red, is anything on fire, is the machine healthy. Read through
an SSH tunnel in a tab kept open all day.

## Where it lives

| Path | Owner |
|---|---|
| `~/.claude/dashboard/` | the live dir — a real dir, not a symlink |
| `index.html`, `serve.sh`, `feed.sh`, `collect-{oncall,reviews}.py`, `fonts/`, `README.md` | symlinks into `~/.dotfiles/config/workboard/` (**public repo**) |
| `collect.sh` | symlink into `~/.dotfiles-work/workboard/` (internal repo) |
| `data/*.json`, `data/*.js`, `.serve.log` | local only, gitignored in both |

**Edit the repo file, never the symlink target's copy** — the symlink means editing
`~/.claude/dashboard/index.html` edits the public repo directly. Which also means:
nothing employer-specific may enter any file except `collect.sh`. No repo slugs, ticket
prefixes, internal hostnames, doc IDs, service names or colleagues' names. Audit
before committing:

```sh
# fill the alternation with your employer, team, repo slug and internal hosts
grep -inE "<employer>|<team>|<repo-slug>|\.internal|docs\.google\.com/document/d/[A-Za-z0-9_-]{20,}" \
  ~/.dotfiles/config/workboard/*.{html,sh,py,md}
```

## First move when it is down or stale

The board is honest about staleness, so "old data" is a feed problem and "blank page"
is a serving problem. Check in this order:

```sh
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8777/index.html   # 000 = not served
crontab -l | grep dashboard                                                  # 3 lines expected
ls -l ~/.claude/dashboard/data/                                              # mtimes < 7 min
cat ~/.claude/dashboard/data/.err
```

Restore the cron if it is missing, then `serve.sh` (idempotent, safe to re-run):

```cron
*/7 * * * * bash -lc '$HOME/.claude/dashboard/collect.sh' >/dev/null 2>&1
*/3 * * * * $HOME/.claude/dashboard/serve.sh --quiet >/dev/null 2>&1
@reboot     $HOME/.claude/dashboard/serve.sh --quiet >/dev/null 2>&1
```

A missing crontab is not the same failure as a dead server: the `*/3` watchdog restarts
the server on its own, so if the server is down the cron is usually down too. Say what
removed it if the evidence exists, and say that you cannot tell if it does not —
`/var/log/syslog` rotates and `/var/spool/cron/crontabs/` is not readable by the user.

## Feeds

One file per panel in `data/`, each written twice: `<name>.json` is the contract,
`<name>.js` wraps it as `WB.set("<name>", {…});` because `fetch()` cannot read a
sibling file from `file://`. `collect.sh` writes both through its `w()`/`js()` helpers —
use them rather than writing files directly.

Every feed carries `generated_at` (UTC, ISO-8601). It drives the per-band staleness
marker, and the band's stale/dead thresholds are the last two arguments to `band()` in
`render()`. A feed that cannot be fetched must keep its previous file: an empty panel
reads as "nothing to do", which is a lie, where old data merely reads as old.

## Changing the page

Read `README.md` in the repo dir first; it carries the constraints. The ones that are
load-bearing:

- One hand-authored file. No build step, no bundler, no framework, no CDN.
- Self-hosted fonts only, all OFL, licenses in `fonts/LICENSES/`.
- Light ground only; colour is never the only carrier of state — every status is a word
  plus a drawn SVG mark.
- Must render correctly with any feed missing or stale. That is the normal case, not
  the edge case.
- Panel and column widths persist in `localStorage` keyed by each panel's stable
  `data-id`. Renaming a `data-id` silently resets that panel's saved width.

To add a panel: add its name to `FILES`, push a `panel(...)` in `render()`, give it a
stable `data-id`, and have something write `data/<name>.json`.

## Verifying a change

There is no browser on the box, so never claim how it looks. What can be checked:

```sh
bash ~/.claude/dashboard/collect.sh              # prints the feeds it wrote
jq . ~/.claude/dashboard/data/<feed>.json        # contract intact
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8777/index.html
```

For JS changes, extract the script blocks and `node --check` them. Then say what was
verified and leave the visual verdict to the user.
