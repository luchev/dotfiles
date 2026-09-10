---
name: confluence
description: Read and write Confluence wiki pages. Use when the user gives a Confluence URL or asks to read, append to, or update a wiki page.
---

# /confluence — Read & write Confluence pages

## FIRST: which deployment is the URL on?

Confluence comes in two flavours with different APIs and different auth:

- **Cloud** (`*.atlassian.net/wiki/...`) — REST API v2, token auth. If an MCP or CLI
  integration is configured for the site, prefer it over raw curl.
- **Data Center / Server** (self-hosted) — REST API v1 at `/rest/api/content/<id>`,
  usually session- or PAT-authenticated.

Check the host before choosing a path. Using the wrong API returns a confusing 404 on a
page that plainly exists.

## Reading

```bash
# DC / Server
curl -sS -H "Authorization: Bearer $WIKI_TOKEN" \
  "$WIKI/rest/api/content/<id>?expand=body.storage,version" | jq -r '.body.storage.value'
```

Always `get` the page first: confirm the id, the title, and the **current version**.

## Writing

Every update must send `version.number = current + 1`; the API rejects a stale version
rather than merging. Read, increment, write.

```bash
curl -sS -X PUT -H "Authorization: Bearer $WIKI_TOKEN" -H 'Content-Type: application/json' \
  "$WIKI/rest/api/content/<id>" -d @page.json
```

## Body format: storage format, NOT markdown

The body is **storage format** (XHTML-ish), on both deployments. Author in a markdown
subset and convert, supporting:

- `#` / `##` / `###` → headings
- ` ```lang ... ``` ` → code macro (language optional)
- `- item` → bullet list
- blank-line-separated → paragraphs
- `**bold**`, `` `code` `` → inline

For tables, panels or expand macros, write raw storage XHTML directly. Code macro raw
form:

```
<ac:structured-macro ac:name="code"><ac:parameter ac:name="language">bash</ac:parameter><ac:plain-text-body><![CDATA[
your commands
]]></ac:plain-text-body></ac:structured-macro>
```

Inspect the generated XHTML before pushing it — a malformed macro renders as raw text on
a page other people read.

## Workflow

1. `get` the page: confirm id, title, current version.
2. For an existing page, read the current body and decide append vs. full rewrite.
3. Author the new content, convert to storage format, inspect it.
4. Write, then re-read to confirm the version bumped and the page renders.

## Gotchas

- **This edits a shared wiki.** Only write when the user explicitly asks, and confirm the
  target page id. Prefer appending a section over replacing the body, so a mistake cannot
  clobber someone else's work.
- The numeric id is what the API needs — pull it from `.../pages/<id>/<slug>` or
  `?pageId=<id>`, not the slug.
- A page you did not create belongs to someone else. Write access is not authorisation.
