#!/usr/bin/env python3
"""Turn the oncall investigation Google Doc into the board's alerts feed.

The doc is the loop's own output and follows a fixed per-alert template:
    ## <emoji> <title>
    **Status: ...**
    **Fired · ...**
    **Root cause. ...**
    **Evidence.** ...
    **Fix. ...**

Reads the markdown the google-workspace downloader already produces; it does not
call the API itself, so it is cheap enough to run on the board's cron.
"""
import json, os, re, sys, glob, datetime

DOC_DIR = os.path.expanduser("~/Documents/google-workspace")
OUT = os.path.expanduser("~/.claude/dashboard/data")


def newest_doc():
    hits = glob.glob(os.path.join(DOC_DIR, "*oncall*", "*.md"))
    return max(hits, key=os.path.getmtime) if hits else None


def clean(s):
    s = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", s)      # links -> text
    s = s.replace("<u>", "").replace("</u>", "")
    s = s.replace("**", "").replace("~~", "")
    return re.sub(r"\s+", " ", s).strip()


def first_url(s):
    m = re.search(r"\((https?://[^)]+)\)", s)
    return m.group(1) if m else None


FIELDS = [
    ("status", re.compile(r"^\**Status[:.]\s*", re.I)),
    ("fired", re.compile(r"^\**Fired\s*[·:.]?\s*", re.I)),
    ("root_cause", re.compile(r"^\**Root cause[.:]\s*", re.I)),
    ("evidence", re.compile(r"^\**Evidence[.:]\s*", re.I)),
    ("fix", re.compile(r"^\**Fix[.:]\s*", re.I)),
]


def parse(md):
    lines = md.splitlines()
    tab = "active"
    out, cur, field = [], None, None

    def close():
        if cur and cur.get("class"):
            out.append(cur)

    for raw in lines:
        line = raw.rstrip()
        if line.startswith("# TAB:"):
            tab = "annotated" if "Annotated" in line else "active"
            continue
        if line.startswith("# ") or line.startswith("## Summary") or line.startswith("## Excluded") or line.startswith("## Log"):
            close(); cur = None; continue
        if line.startswith("## ") and re.match(r"##\s*(Side finding|Excluded|Log\b)", line, re.I):
            close(); cur = None; field = None; continue
        if line.startswith("## "):
            close()
            title = clean(line[3:])
            closed = ("ANNOTATED" in title) or ("closed" in title.lower()) or ("~~" in line)
            sev = "critical" if "🔴" in line else "warning" if "🟡" in line else None
            title = re.sub(r"^[🔴🟡🟢⚪️\s]+", "", title)
            title = re.sub(r"\s*·?\s*ANNOTATED,? closed\s*$", "", title, flags=re.I).strip()
            cur = {"class": title, "tab": tab, "closed": closed, "severity": sev,
                   "url": first_url(line), "status": None, "fired": None,
                   "root_cause": None, "evidence": None, "fix": None, "runbook": None}
            field = None
            continue
        if cur is None or not line.strip():
            continue
        matched = False
        for name, rx in FIELDS:
            if rx.match(line):
                body = clean(rx.sub("", line))
                cur[name] = body or None
                if name == "fired" and "Runbook" in line:
                    cur["runbook"] = first_url(line)
                field = name
                matched = True
                break
        if matched:
            continue
        if field == "evidence":         # evidence is a bullet list, keep it as one
            b = clean(line)
            b = re.sub(r"^\*\s*", "", b)
            if b:
                cur.setdefault("evidence_items", []).append(b)
            continue
        if field:                       # continuation of the previous field
            extra = clean(line)
            if extra:
                cur[field] = ((cur[field] + " ") if cur[field] else "") + extra
    close()
    return out


def state_of(a):
    if a["closed"]:
        return "resolved"
    s = (a["status"] or "").lower()
    if "investigat" in s:
        return "investigating"
    return "new"


def main():
    doc = newest_doc()
    if not doc:
        print("no oncall doc found under " + DOC_DIR, file=sys.stderr)
        return 1
    alerts = parse(open(doc, encoding="utf-8").read())
    active = [a for a in alerts if a["tab"] == "active" and not a["closed"]]
    closed = [a for a in alerts if a["closed"]]

    for a in alerts:
        fix = a.get("fix") or ""
        m = re.search(r"Proposed annotation[^`]*```(.+?)```", fix, re.S)
        if m:
            a["annotation"] = clean(m.group(1))
            a["fix"] = clean(re.sub(r"Proposed annotation.*$", "", fix, flags=re.S)) or None

    LIMIT = 700
    for a in alerts:
        for k in ("status", "fired", "root_cause", "fix", "annotation"):
            v = a.get(k)
            if v and len(v) > LIMIT:
                a[k] = v[:LIMIT].rsplit(" ", 1)[0] + " …"

    items = []
    for a in active + closed:
        items.append({
            "class": a["class"],
            "status": state_of(a),
            "severity": a["severity"],
            "url": a["url"], "runbook": a["runbook"],
            "detail": {k: a[k] for k in ("status", "fired", "root_cause", "fix", "annotation") if a.get(k)},
            "evidence": (a.get("evidence_items") or [])[:14],
        })

    payload = {
        "generated_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "source_doc_age_min": int((datetime.datetime.now().timestamp() - os.path.getmtime(doc)) / 60),
        "open": len(active),
        "items": items,
    }
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "oncall.json"), "w") as f:
        json.dump(payload, f, indent=1)
    with open(os.path.join(OUT, "oncall.js"), "w") as f:
        f.write("WB.set(\"oncall\",")
        json.dump(payload, f, indent=1)
        f.write(");\n")
    print(f"oncall: {len(active)} open, {len(closed)} closed, from {os.path.basename(doc)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
