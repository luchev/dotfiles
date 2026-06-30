# CLAUDE.md

Global behavioral guidelines for all projects. Merge with project-specific instructions as needed.

@~/.dotfiles/claude/notes/engineering-principles.md

## Zellij pane topic

When you've understood what a new session is about (typically after the first user prompt and any initial exploration), call:

```
bash ~/.dotfiles/claude/zellij-status.sh topic "<short summary, ≤40 chars>"
```

The topic appears as the pane label fallback (e.g. `💤 · <topic>`) and persists across turns. Update it if the session's focus shifts substantially. Don't call it for trivial one-off tasks where the session will be short.
