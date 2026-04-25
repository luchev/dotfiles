---
name: summarize
description: Print a concise session summary — task, progress, outstanding items, PR/diff status, and key notes.
---

# Session Summary

Produce a **short, scannable** summary of this session using only what is already in the conversation context. Do NOT run any shell commands or external tools.

## Output format

Print **only** this block — keep each line to one sentence max:

```
## Session Summary

**Task:** <one-line description of what we're working on>

**Progress:**
- [x] <completed item>
- [ ] <outstanding item>

**Issue:** <issue/ticket URL if associated with this session, or omit this line>

**PR:** <PR URL and status if mentioned in conversation, or "None yet">

**Notes:** <blockers, decisions, or key context worth remembering — omit if nothing notable>
```

Rules:
- Omit the **Notes** line entirely if there's nothing notable.
- Omit the **Issue** line if no ticket/issue is associated with this session.
- Use `[x]` for done, `[ ]` for not done.
- Infer everything from the conversation history — no git or shell calls.
- Be brutal about brevity — the whole output should fit in a terminal screen.
