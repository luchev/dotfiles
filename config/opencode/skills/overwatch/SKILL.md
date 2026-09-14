---
name: overwatch
description: One place to see, start and stop every background watch loop and the Work Board. Use when the user says "overwatch", "what's running", "what loops are up", "start everything", "stop the loops", "is the board up", "status of my loops", or asks why a loop went quiet. Drives loop-watch-oncall, loop-watch-reviews, loop-watch-pr, loop-update-workdoc and the workboard skill; it never reimplements what they do.
---

# Overwatch

The supervisor for the background work. It answers "what is actually running right now",
starts and stops the loops, and keeps their JSON sinks pointed at the board.

It owns no watching logic of its own. Every action is a delegation to the skill that
owns it — read that skill before driving it, and never inline its steps here.

## Invocation

```
/overwatch [verb] [target] [--sink json|doc|both]
```

| Invocation | Does |
|---|---|
| `/overwatch` | Status for everything. The default, because it is the usual question. |
| `/overwatch <target>` | Status for one target. |
| `/overwatch start` | Start the three cron loops and the board. |
| `/overwatch start <target>` | Start one. |
| `/overwatch stop` | Stop every cron loop and every PR agent. State is kept. |
| `/overwatch stop <target>` | Stop one. |
| `/overwatch board` | The board row alone — it fails differently from the loops. |
| `/overwatch pr <N>` | Start a watch on PR `N`. Needs the number; never part of `start`. |

Targets: `oncall`, `reviews`, `workdoc`, `board`, `pr <N>`.

`--sink json|doc|both` passes straight through to whichever loops this invocation
starts, and is ignored by `status` and `stop`. `start --sink json` brings everything up
feeding the board and writing no docs.

**`start` is idempotent.** A target already in `CronList` is skipped with a line saying
so, never restarted and never an error — so it is safe to type whenever you are unsure
what is up. There is no `restart` verb: `stop <target>` then `start <target>`.

## What it supervises

| Thing | Skill | State | Liveness signal |
|---|---|---|---|
| Oncall alerts | `loop-watch-oncall` | `~/.claude/oncall-watch/` | a `CronList` job whose prompt names the skill |
| Review queue | `loop-watch-reviews` | `~/.claude/loop-watch-reviews/` | same |
| Workdoc | `loop-update-workdoc` | `~/.config/workdoc/loop/` | same |
| A single PR | `loop-watch-pr` | `~/.claude/loop-watch-pr/<owner>__<repo>__<pr>.json` | a live background agent, one per PR |
| The board | `workboard` | `~/.claude/dashboard/` | `curl 127.0.0.1:8777` **and** 3 crontab lines |

## Status — the one rule that matters

**A fresh state directory is not evidence that a loop is running.** The cron jobs are
session-local: they die with the Claude session that created them, and nothing on disk
restores them, while the state tree keeps whatever the last cycle left. `ls` proves
history; only `CronList` proves a loop is armed *in this session*.

The board's crontab is the opposite case — it is real crontab state that outlives every
session, so it is checked with `crontab -l`, and its absence means something removed it.

Report each row as one of:

| Verdict | Means |
|---|---|
| `running` | job present in `CronList` (or a live agent for a PR watch) |
| `armed elsewhere` | state advanced recently but no job here — another session owns it, or owned it |
| `stale` | no job, and the newest state file is older than the loop's own cadence |
| `never run` | no state dir, or no `state.json` and no tick marker |

Do not collapse `armed elsewhere` into `running`. Restarting a loop another live session
owns gives two jobs writing one state dir, which corrupts it.

```sh
crontab -l | grep dashboard | wc -l                                       # expect 3
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8777/index.html # expect 200
for d in ~/.claude/oncall-watch ~/.claude/loop-watch-reviews ~/.config/workdoc/loop; do
  printf '%-34s %s\n' "$d" "$(ls -t "$d" 2>/dev/null | head -1)"
done
ls -t ~/.claude/loop-watch-pr/*.json 2>/dev/null
```

Then `CronList`, and the agent list for PR watches. Print one line per row, newest
signal first. No prose around it.

## start

Invoke the owning skill; never hand-roll a `CronCreate` for a loop that schedules
itself. Before starting any loop, `CronList` — if it is already there, print
`skipped, already running` for that row and move on rather than arming a second one.

Bare `start` is `loop-watch-oncall`, `loop-watch-reviews`, `loop-update-workdoc`, then
the board, each with the invocation's `--sink` if one was given. PR watches are never
part of it — they need a number, and they end when the PR lands.

For the board, restoring the cron is the fix; starting the server by hand leaves it
unsupervised:

```cron
*/7 * * * * bash -lc '$HOME/.claude/dashboard/collect.sh' >/dev/null 2>&1
*/3 * * * * $HOME/.claude/dashboard/serve.sh --quiet >/dev/null 2>&1
@reboot     $HOME/.claude/dashboard/serve.sh --quiet >/dev/null 2>&1
```

Restoring a user crontab overwrites whatever is there. Read `crontab -l` first, add to
it, never replace it blind.

## stop

`CronDelete` for a cron loop, `TaskStop` for a PR watch's agent. Stopping is not
cleanup: leave every state dir alone, because it is what the loop resumes from. Say
which jobs were removed and which state was kept. `--sink` is ignored here.

## Feeding the board

Each loop's `--sink json` writes a `state.json` the board can render. That is the whole
integration — no new collector, no copy step inside a loop.

| Loop | Sink file | Board feed |
|---|---|---|
| `loop-watch-oncall` | `~/.claude/oncall-watch/state.json` | `data/oncall.json` |
| `loop-watch-reviews` | `~/.claude/loop-watch-reviews/state.json` | `data/reviews.json` |
| `loop-update-workdoc` | `~/.config/workdoc/loop/state.json` | `data/tasks.json` |
| `loop-watch-pr` | `~/.claude/loop-watch-pr/*.json` | folded into `data/prs.json` |

Sink precedence is the loop's own: `--sink` on the invocation beats `sink=` in its
`README.md`, which beats `both`. When a loop runs under `--sink doc` its `state.json`
goes stale while the loop is perfectly healthy, so a stale sink is a fact about the
sink, not about the loop — check `CronList` before calling it dead.

The board reads `data/*.json` and nothing else. If a feed should come from a sink rather
than from the board's own collector, that wiring belongs in `collect.sh`, which the
`workboard` skill owns.

## Rules

- Delegate, never reimplement. If an action needs more than "invoke skill X", it belongs
  in skill X.
- Never infer `running` from file freshness, and never infer `dead` from a quiet sink.
- Never start a loop that `CronList` already shows.
- Never delete loop state as part of stopping.
- Report what was verified and how. A status claim with no command behind it is not a
  status.
