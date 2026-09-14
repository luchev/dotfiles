#!/usr/bin/env python3
"""Turn the PR-review-watch Google Doc into the board's review feed.

Template the loop writes, one section per PR:
    ## **<title> · <Verdict>**
    [#257610](url) · `author` · reviewed <sha> · <date>
    **What.** ...
    **Findings.**
    * [`file.go:123`](permalink), [`:456`](permalink) — the finding
"""
import json, os, re, sys, glob, datetime

DOC_DIR = os.path.expanduser("~/Documents/google-workspace")
OUT = os.path.expanduser("~/.claude/dashboard/data")
LINK = re.compile(r"\[([^\]]+)\]\((https?://[^)]+)\)")


def newest_doc():
    hits = glob.glob(os.path.join(DOC_DIR, "*review*", "*.md"))
    return max(hits, key=os.path.getmtime) if hits else None


def plain(s):
    s = LINK.sub(r"\1", s)
    for junk in ("<u>", "</u>", "**", "~~", "`"):
        s = s.replace(junk, "")
    return re.sub(r"\s+", " ", s).strip()


def links_in(s):
    return [{"label": plain(m.group(1)), "url": m.group(2)} for m in LINK.finditer(s)]


def parse(md):
    out, cur, field = [], None, None
    for raw in md.splitlines():
        line = raw.rstrip()
        if line.startswith("## ") and re.match(r"##\s*\**Log\b", line):
            if cur: out.append(cur)
            cur = None; continue
        if line.startswith("## "):
            if cur: out.append(cur)
            head = plain(line[3:])
            verdict = "unreviewed"
            m = re.search(r"·\s*(Concerns|Nits|LGTM|Approve[d]?|Blocking|Clean)\s*$", head, re.I)
            if m:
                verdict = m.group(1).lower()
                head = head[:m.start()].strip(" ·")
            cur = {"title": head, "verdict": verdict, "what": None,
                   "findings": [], "number": None, "author": None,
                   "url": None, "reviewed": None}
            field = None
            continue
        if cur is None or not line.strip():
            continue
        if cur["number"] is None and re.search(r"\[#?\w?\d{4,}\]", line):
            ls = links_in(line)
            if ls:
                cur["url"] = ls[0]["url"]
                cur["number"] = ls[0]["label"].lstrip("#")
            a = re.search(r"`([^`]+)`", line)
            if a: cur["author"] = a.group(1)
            d = re.search(r"(\d{4}-\d{2}-\d{2})", line)
            if d: cur["reviewed"] = d.group(1)
            continue
        if re.match(r"^\**What[.:]", line):
            cur["what"] = plain(re.sub(r"^\**What[.:]\s*", "", line)); field = "what"; continue
        if re.match(r"^\**Findings[.:]", line):
            field = "findings"
            rest = plain(re.sub(r"^\**Findings[.:]\s*", "", line))
            if rest: cur["findings"].append({"text": rest, "links": links_in(line)})
            continue
        if field == "findings" and line.lstrip().startswith("*"):
            body = re.sub(r"^\s*\*\s*", "", line)
            cur["findings"].append({"text": plain(body), "links": links_in(body)})
            continue
        if field == "what" and cur["what"]:
            cur["what"] += " " + plain(line)
    if cur: out.append(cur)
    return [c for c in out if c["number"]]


def main():
    doc = newest_doc()
    if not doc:
        print("no review doc found", file=sys.stderr); return 1
    revs = parse(open(doc, encoding="utf-8").read())
    now = datetime.datetime.now(datetime.timezone.utc)
    items = []
    for r in revs:
        age = None
        if r["reviewed"]:
            try:
                d = datetime.datetime.strptime(r["reviewed"], "%Y-%m-%d").replace(tzinfo=datetime.timezone.utc)
                age = int((now - d).total_seconds() / 3600)
            except ValueError:
                pass
        items.append({
            "number": r["number"], "title": r["title"], "author": r["author"] or "",
            "url": r["url"], "verdict": r["verdict"], "age_h": age,
            "what": r["what"], "findings": r["findings"][:10],
        })
    payload = {"generated_at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
               "source_doc_age_min": int((datetime.datetime.now().timestamp() - os.path.getmtime(doc)) / 60),
               "items": items}
    os.makedirs(OUT, exist_ok=True)
    json.dump(payload, open(os.path.join(OUT, "reviews.json"), "w"), indent=1)
    with open(os.path.join(OUT, "reviews.js"), "w") as f:
        f.write('WB.set("reviews",'); json.dump(payload, f, indent=1); f.write(");\n")
    print(f"reviews: {len(items)} from {os.path.basename(doc)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
