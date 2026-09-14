#!/usr/bin/env python3
"""Emit one JSON object per session touched since --since (epoch ms), newest last.

Sources: claude-mem session_summaries (Claude Code) and opencode.db session (opencode).
Paths default to the standard install locations and can be overridden with --claude-db /
--opencode-db or $CLAUDE_MEM_DB / $OPENCODE_DB. A missing store is skipped, not an error.
Both stores are sqlite; python is used because sqlite3(1) is not always installed.
Output is JSONL so the caller can group with jq.
"""
import argparse, json, os, re, sqlite3, sys
from datetime import datetime, timezone

CLAUDE_DB = os.path.expanduser(os.environ.get("CLAUDE_MEM_DB", "~/.claude-mem/claude-mem.db"))
OPENCODE_DB = os.path.expanduser(os.environ.get("OPENCODE_DB", "~/.local/share/opencode/opencode.db"))
TICKET = re.compile(r"\b[A-Z][A-Z0-9]{1,9}-\d+\b")


def ro(path):
    if not os.path.exists(path):
        return None
    return sqlite3.connect(f"file:{path}?mode=ro", uri=True)


def iso(ms):
    return datetime.fromtimestamp(ms / 1000, timezone.utc).isoformat(timespec="seconds")


def key_for(strong, weak=(), fallback=None):
    """Ticket from a strong field (project, title) wins. Otherwise a ticket mentioned
    in the body counts only if the body names exactly one — several means the session
    was reading around, not working a ticket."""
    for t in strong:
        if t:
            m = TICKET.search(t)
            if m:
                return m.group(0)
    found = {m for t in weak if t for m in TICKET.findall(t)}
    if len(found) == 1:
        return found.pop()
    for t in list(strong) + [fallback]:
        if t:
            return t.strip().split("/")[-1][:40]
    return "misc"


def claude_rows(since):
    db = ro(CLAUDE_DB)
    if not db:
        return
    db.row_factory = sqlite3.Row
    q = """select project, request, investigated, learned, completed, next_steps, notes,
                  created_at_epoch, memory_session_id
           from session_summaries where created_at_epoch > ? order by created_at_epoch"""
    for r in db.execute(q, (since,)):
        d = dict(r)
        yield {
            "source": "claude",
            "key": key_for(
                (d["project"], d["request"]),
                (d["completed"], d["next_steps"], d["investigated"], d["notes"]),
            ),
            "project": d["project"],
            "session": d["memory_session_id"],
            "updated_ms": d["created_at_epoch"],
            "updated": iso(d["created_at_epoch"]),
            "request": d["request"],
            "investigated": d["investigated"],
            "learned": d["learned"],
            "completed": d["completed"],
            "next_steps": d["next_steps"],
            "notes": d["notes"],
        }


def opencode_rows(since, max_parts):
    db = ro(OPENCODE_DB)
    if not db:
        return
    db.row_factory = sqlite3.Row
    q = """select id, title, directory, path, slug, summary_files, summary_additions,
                  summary_deletions, time_updated
           from session where time_updated > ? and parent_id is null order by time_updated"""
    for r in db.execute(q, (since,)):
        d = dict(r)
        prompts, last_reply = [], ""
        pq = """select p.data from part p join message m on m.id = p.message_id
                where p.session_id = ? order by p.time_created desc limit ?"""
        for (raw,) in db.execute(pq, (d["id"], max_parts)):
            try:
                j = json.loads(raw)
            except ValueError:
                continue
            if j.get("type") != "text" or not j.get("text"):
                continue
            txt = " ".join(j["text"].split())
            if not last_reply:
                last_reply = txt[:800]
            elif len(prompts) < 3:
                prompts.append(txt[:300])
        if len(last_reply) < 200 and not d["summary_files"]:
            continue  # greetings, aborted sessions: nothing happened
        yield {
            "source": "opencode",
            "key": key_for(
                (d["title"],),
                (last_reply, " ".join(prompts)),
                fallback=d["path"] or d["directory"],
            ),
            "project": d["path"] or d["directory"],
            "session": d["id"],
            "updated_ms": d["time_updated"],
            "updated": iso(d["time_updated"]),
            "request": d["title"],
            "investigated": " | ".join(reversed(prompts)) or None,
            "learned": None,
            "completed": last_reply or None,
            "next_steps": None,
            "notes": "files %s (+%s/-%s)" % (d["summary_files"], d["summary_additions"], d["summary_deletions"])
            if d["summary_files"] else None,
        }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--since", type=int, required=True, help="epoch ms; sessions updated after this")
    ap.add_argument("--exclude-session", action="append", default=[], help="session id to skip")
    ap.add_argument("--max-parts", type=int, default=60)
    ap.add_argument("--claude-db", help="override the claude-mem sqlite path")
    ap.add_argument("--opencode-db", help="override the opencode sqlite path")
    a = ap.parse_args()
    global CLAUDE_DB, OPENCODE_DB
    CLAUDE_DB = os.path.expanduser(a.claude_db or CLAUDE_DB)
    OPENCODE_DB = os.path.expanduser(a.opencode_db or OPENCODE_DB)

    rows = list(claude_rows(a.since)) + list(opencode_rows(a.since, a.max_parts))
    rows = [r for r in rows if r["session"] not in a.exclude_session]
    rows.sort(key=lambda r: r["updated_ms"])
    for r in rows:
        json.dump(r, sys.stdout, ensure_ascii=False)
        sys.stdout.write("\n")


if __name__ == "__main__":
    main()
