---
name: restore
description: >
  Restore a saved session from ~/.config/opencode/sessions/<name>.md, print its
  context into the conversation, then delete the file so it is not replayed
  again. Use at the start of a new conversation to pick up where you left off.
allowedTools:
  - Bash(ls ~/.config/opencode/sessions/)
  - Bash(rm ~/.config/opencode/sessions/*)
  - Read
---

# /restore — Restore Saved Session

Load a saved session file, inject its context, then remove the file.

## Argument Parsing

- (empty) — list available sessions and ask the user to pick one
- `<name>` — restore this specific session

## Step 1: Resolve the session file

If no name argument:

```bash
ls ~/.config/opencode/sessions/*.md 2>/dev/null
```

List only `.md` session files. If none exist, print "No saved sessions. Use /save to save the current session." and stop.

Otherwise print the list of names (without the `.md` extension) and ask the user which session to restore. Stop here until they answer.

If a name argument was given, the target file is `~/.config/opencode/sessions/<name>.md`.
If the file does not exist, print an error listing available sessions (run `ls ~/.config/opencode/sessions/*.md 2>/dev/null`) and stop.

## Step 2: Read and print the session

Read `~/.config/opencode/sessions/<name>.md` and print its full contents verbatim into the conversation under a header:

```
## Restored Session: <name>

<file contents>
```

## Step 3: Delete the file

```bash
rm ~/.config/opencode/sessions/<name>.md
```

This prevents the same session from being accidentally replayed in a future `/restore` call.

## Step 4: Orient and prompt

After printing the session, add:

```
---
Session file deleted. Context is now loaded.

**Where we left off:** <restate the Open Items from the session in 1–2 sentences>

Ready to continue — just say "go" or tell me where to start.
```

Do not begin executing any work until the user confirms.
