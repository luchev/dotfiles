---
name: jira
description: Create, update, and track Jira issues from the CLI. Use when creating tickets, updating status, linking issues, commenting, or managing sprints.
---

# Managing Jira Issues

Works against any Atlassian Cloud site. Everything below goes through the REST API with a
small curl wrapper; a dedicated Jira CLI works too if one is installed.

## Setup (run once)

Create `jira-curl`, a wrapper that adds auth and the base URL so no command has to repeat
them:

```bash
cat > ~/.local/bin/jira-curl << 'SCRIPT'
#!/usr/bin/env bash
# usage: jira-curl GET /rest/api/3/issue/PROJ-123
METHOD=$1; shift
PATH_=$1; shift
curl -sS -X "$METHOD" \
  -H "Authorization: Bearer $JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  "$JIRA_BASE_URL$PATH_" "$@"
SCRIPT
chmod +x ~/.local/bin/jira-curl
```

Set `JIRA_BASE_URL` and `JIRA_TOKEN` in your shell profile. Keep the token out of the repo
and out of any command you paste into a ticket or PR.

## API version

Atlassian Cloud is migrating off `/rest/api/2`; prefer **`/rest/api/3`** and fall back to
`2` only when an endpoint has no v3 form. A v2 call that suddenly returns a deprecation
error is not an auth problem — switch the version before debugging anything else.

## Commands

```bash
# read
jira-curl GET  "/rest/api/3/issue/PROJ-123"
jira-curl GET  "/rest/api/3/search?jql=assignee=currentUser()+AND+statusCategory!=Done"

# create
jira-curl POST "/rest/api/3/issue" -d '{"fields":{
  "project":{"key":"PROJ"},"summary":"...","issuetype":{"name":"Task"}}}'

# update, comment, transition
jira-curl PUT  "/rest/api/3/issue/PROJ-123" -d '{"fields":{"summary":"..."}}'
jira-curl POST "/rest/api/3/issue/PROJ-123/comment" -d '{"body":"..."}'
jira-curl POST "/rest/api/3/issue/PROJ-123/transitions" -d '{"transition":{"id":"31"}}'

# link two issues
jira-curl POST "/rest/api/3/issueLink" -d '{"type":{"id":"10003"},
  "inwardIssue":{"key":"PROJ-1"},"outwardIssue":{"key":"PROJ-2"}}'
```

Transition ids are per-project — list them with
`GET /rest/api/3/issue/PROJ-123/transitions` rather than guessing. A transition to a
closed state usually requires a `resolution` in the same call.

## Sprints

Sprint endpoints live under the Agile API and need the board id:

```bash
jira-curl GET  "/rest/agile/1.0/board/<BOARD>/sprint?state=active,future"
jira-curl POST "/rest/agile/1.0/sprint/<SPRINT>/issue" -d '{"issues":["PROJ-123"]}'
```

Future sprints often have no `startDate` — order them by `id`, not by date, or they sort
arbitrarily. Never start a sprint that is already complete.

## Gotchas

- **Assignee is an account id**, not a username or email:
  `{"fields":{"assignee":{"accountId":"..."}}}`. Look it up via
  `/rest/api/3/user/search?query=<email>`. Setting the wrong shape often fails silently —
  read the issue back and confirm.
- **Quote URLs containing `?`** in zsh, or the shell globs them.
- **Bodies need `-d`.** A PUT/POST without one sends an empty body and returns 400.
- **Close, never delete.** Deleting loses history; a closed issue stays searchable.
- **Never overwrite someone's comment** with a PUT. Add a new one.
- Keep comments terse — the ticket is a record, not a transcript.
