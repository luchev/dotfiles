#!/usr/bin/env python3
"""Rebuild the claude-mem index from the canonical markdown memory.

The markdown under ~/.claude/projects/*/memory/ is the record of truth; the
claude-mem SQLite + Chroma store is a derived index. This script rebuilds that
index, so it is what makes the store disposable.

Idempotent: records already imported under a migration session are skipped by
title. The /api/import endpoint does NOT deduplicate on its own — re-posting
the same payload creates duplicates — so the skip happens here, before posting.

Only migration-sourced records are considered. Observations captured natively
by claude-mem during normal work are never touched.

Usage:
    mem-migrate.py            # import everything not already present
    mem-migrate.py go-code    # only batches whose label matches the argument
"""
import json, os, re, time, urllib.request, glob, sys, sqlite3

WORKER = "http://127.0.0.1:37700"
HOME = os.path.expanduser("~")
DB = os.path.join(HOME, ".claude-mem", "claude-mem.db")

# metadata.type in the markdown frontmatter -> claude-mem observation type
TYPE_MAP = {
    "feedback": "decision",
    "project": "other",
    "reference": "discovery",
    "user": "other",
}


def parse_frontmatter(raw):
    """Return (meta_dict, body). Hand-rolled: no yaml module guaranteed."""
    if not raw.startswith("---"):
        return {}, raw
    end = raw.find("\n---", 3)
    if end == -1:
        return {}, raw
    head, body = raw[3:end], raw[end + 4:]
    meta = {}
    for line in head.splitlines():
        m = re.match(r"^\s*(\w+):\s*(.*)$", line)
        if m:
            k, v = m.group(1), m.group(2).strip().strip('"\'')
            if v:
                meta[k] = v
    return meta, body.lstrip("\n")


def iso_epoch(ts=None):
    ts = ts or time.time()
    return time.strftime("%Y-%m-%dT%H:%M:%S.000Z", time.gmtime(ts)), int(ts * 1000)


def derive_index_fields(title, description, body):
    """Chroma embeds narrative/facts/concepts only — title and text are NOT
    indexed. Records without these are stored but permanently unsearchable by
    text, so derive them structurally from the markdown."""
    lines = [l.strip() for l in body.splitlines()]
    # Bullets and short declarative lines carry the actual claims.
    facts = []
    for l in lines:
        if re.match(r"^[-*+]\s+\S", l) or re.match(r"^\d+\.\s+\S", l):
            facts.append(re.sub(r"^([-*+]|\d+\.)\s+", "", l))
        elif 25 < len(l) < 220 and not l.startswith(("#", "|", "```", ">")):
            facts.append(l)
    facts = [f for f in facts if f][:12]

    para = ""
    for l in lines:
        if l and not l.startswith(("#", "|", "```", ">", "-", "*")):
            para = l
            break
    narrative = " ".join(x for x in (description, para) if x)[:1200] or title

    words = re.findall(r"[a-z0-9]+", f"{title} {description}".lower())
    stop = {"the","a","an","and","or","for","to","of","in","is","it","this","that",
            "with","on","at","by","be","not","no","use","user","when","from","as","md"}
    concepts, seen = [], set()
    for w in words:
        if len(w) > 2 and w not in stop and w not in seen:
            seen.add(w)
            concepts.append(w)
    return narrative, facts, concepts[:15]


def observation(mem_id, project, otype, title, text, subtitle=None):
    iso, ep = iso_epoch()
    narrative, facts, concepts = derive_index_fields(title, subtitle or "", text)
    o = {
        "memory_session_id": mem_id,
        "project": project,
        "type": otype,
        "title": title[:200],
        "text": text,
        "narrative": narrative,
        "facts": json.dumps(facts),
        "concepts": json.dumps(concepts),
        "created_at": iso,
        "created_at_epoch": ep,
    }
    if subtitle:
        o["subtitle"] = subtitle[:200]
    return o


def session(mem_id, project):
    iso, ep = iso_epoch()
    return {
        "content_session_id": mem_id, "memory_session_id": mem_id,
        "project": project, "platform_source": "migration",
        "started_at": iso, "started_at_epoch": ep,
        "completed_at": iso, "completed_at_epoch": ep,
        "status": "completed",
    }


def post(payload):
    body = json.dumps(payload).encode()
    req = urllib.request.Request(
        f"{WORKER}/api/import", data=body,
        headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read().decode())


def collect_memory_dirs():
    """Per-project memory files. MEMORY.md is an index of these; skip it."""
    groups = {}
    for md in sorted(glob.glob(f"{HOME}/.claude/projects/*/memory/*.md")):
        project = md.split("/projects/")[1].split("/")[0]
        if os.path.basename(md) == "MEMORY.md":
            continue
        meta, body = parse_frontmatter(open(md, encoding="utf-8").read())
        name = meta.get("name") or os.path.basename(md)[:-3]
        otype = TYPE_MAP.get(meta.get("type", ""), "other")
        groups.setdefault(project, []).append(
            observation(f"migration-memory-{project}", project, otype,
                        name, body, meta.get("description")))
    return groups


def collect_log():
    """Split the observation log on its entry headers."""
    p = f"{HOME}/.config/opencode/skill-observations/log.md"
    if not os.path.exists(p):
        return []
    raw = open(p, encoding="utf-8").read()
    parts = re.split(r"^### Observation (\d+): (.*)$", raw, flags=re.M)
    out = []
    for i in range(1, len(parts) - 1, 3):
        num, title, body = parts[i], parts[i + 1], parts[i + 2]
        out.append(observation("migration-skill-observations", "global",
                               "decision", f"Observation {num}: {title}", body.strip()))
    return out


def collect_files(paths, mem_id, otype):
    out = []
    for p in paths:
        if not os.path.exists(p):
            continue
        out.append(observation(mem_id, "global", otype,
                               os.path.basename(p), open(p, encoding="utf-8").read()))
    return out


def existing_titles(mem_id):
    """Titles already imported under this migration session.

    Read directly from SQLite: the import endpoint has no dedupe, and there is
    no read API that exposes titles cheaply enough to page through.
    """
    if not os.path.exists(DB):
        return set()
    try:
        c = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
        return {r[0] for r in c.execute(
            "select title from observations where memory_session_id=?", (mem_id,))}
    except sqlite3.Error:
        return set()


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else None
    batches = []

    for project, obs in collect_memory_dirs().items():
        batches.append((f"memory:{project}", f"migration-memory-{project}", project, obs))

    log = collect_log()
    if log:
        batches.append(("skill-observations", "migration-skill-observations", "global", log))

    cfg = collect_files(
        [f"{HOME}/.config/opencode/instructions.md"] + sorted(glob.glob(f"{HOME}/.claude/rules/*.md")),
        "migration-config", "decision")
    if cfg:
        batches.append(("instructions+rules", "migration-config", "global", cfg))

    sess = collect_files(sorted(glob.glob(f"{HOME}/.config/opencode/sessions/*.md")),
                         "migration-sessions", "other")
    if sess:
        batches.append(("opencode-sessions", "migration-sessions", "global", sess))

    total = skipped_total = 0
    for label, mem_id, project, obs in batches:
        if only and only not in label:
            continue
        have = existing_titles(mem_id)
        fresh = [o for o in obs if o["title"] not in have]
        skipped_total += len(obs) - len(fresh)
        if not fresh:
            print(f"{label:42s} sent=   0 imported=   0 already={len(obs):4d}")
            continue
        res = post({"sessions": [session(mem_id, project)], "summaries": [],
                    "observations": fresh, "prompts": []})
        s = res.get("stats", {})
        print(f"{label:42s} sent={len(fresh):4d} imported={s.get('observationsImported',0):4d} "
              f"already={len(obs)-len(fresh):4d}")
        total += s.get("observationsImported", 0)
    print(f"\nimported: {total}   already present: {skipped_total}")
    if total:
        print("Chroma embeds narrative/facts/concepts asynchronously — verify with:\n"
              "  npx claude-mem search \"<something you know is in there>\"")


if __name__ == "__main__":
    main()
