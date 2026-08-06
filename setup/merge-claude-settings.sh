#!/usr/bin/env bash
# Merge personal keys into ~/.claude/settings.json (dotbot shell step).
#
# An external provisioning tool owns most of this file (apiKeyHelper, env,
# enabledPlugins, otel*, extraKnownMarketplaces) and rewrites it whenever it
# updates. Managing the whole file would mean the two clobbering each other, so
# this merges in only the keys that are genuinely personal and leaves the rest
# of the existing file untouched. Idempotent: safe to re-run every apply.
set -euo pipefail

SETTINGS="${HOME}/.claude/settings.json"
mkdir -p "$(dirname "$SETTINGS")"
current=$(cat "$SETTINGS" 2>/dev/null || true)
[ -n "$current" ] || current='{}'

session_start_context='At the start of any task-oriented session - any interaction where you will use tools and produce deliverables - invoke the task-observer skill before beginning work. This ensures skill improvement opportunities are captured throughout the session. When loading any skill, check the observation log for OPEN observations tagged to that skill and apply their insights to the current work, even if the skill file has not been updated yet. Additionally, the caveman skill is active every session, every response, at ultra intensity by default. Invoke it at the start of the session and keep it active until the user asks for normal mode or asks to stop caveman. Follow the skill own boundaries: use normal prose for security warnings, irreversible-action confirmations, and code, commit, and PR text.'

# shellcheck disable=SC2016
printf '%s' "$current" | jq \
  --arg home "$HOME" \
  --arg ctx "$session_start_context" \
  --argjson allow '[
    "Bash(arh:*)",
    "Bash(awk:*)",
    "Bash(bash:*)",
    "Bash(cat:*)",
    "Bash(cd:*)",
    "Bash(chmod:*)",
    "Bash(diff:*)",
    "Bash(echo:*)",
    "Bash(find:*)",
    "Bash(git:*)",
    "Bash(grep:*)",
    "Bash(head:*)",
    "Bash(jq:*)",
    "Bash(ln:*)",
    "Bash(ls:*)",
    "Bash(mkdir:*)",
    "Bash(mv:*)",
    "Bash(nu:*)",
    "Bash(sed:*)",
    "Bash(sort:*)",
    "Bash(tail:*)",
    "Bash(uniq:*)",
    "Bash(wc:*)",
    "Bash(which:*)",
    "Glob",
    "Grep",
    "WebSearch"
  ]' '
  # Scalars: personal preferences, safe to assert outright.
  .model                              = "sonnet"
| .effortLevel                        = "medium"
| .fastMode                           = false
| .teammateMode                       = "auto"
| .preferredNotifChannel              = "terminal_bell"
| .skipAutoPermissionPrompt           = true
| .permissions.defaultMode            = "auto"
| .permissions.additionalDirectories  = [$home]

  # Union rather than replace: external tooling and per-project prompts add
  # entries here too, and losing them would mean re-approving everything.
| .permissions.allow = ((.permissions.allow // []) + $allow | unique)

  # Drop any previous copy of this hook before re-adding, so repeated
  # apply runs stay idempotent.
| .hooks.SessionStart = ((.hooks.SessionStart // [])
    | map(select((.hooks[0].command // "") | test("task-observer") | not))
    + [{
        hooks: [{
          type: "command",
          timeout: 5,
          command: ("printf '"'"'%s'"'"' " + (
            {hookSpecificOutput: {
              hookEventName: "SessionStart",
              additionalContext: $ctx
            }} | tojson | "'"'"'" + . + "'"'"'"
          ))
        }]
      }])

  # Hard-block the destructive git/chezmoi forms that rules/ only bans in prose.
  # Same drop-then-re-add shape as above to stay idempotent.
| .hooks.PreToolUse = ((.hooks.PreToolUse // [])
    | map(select((.hooks[0].command // "") | test("block-dangerous-git") | not))
    + [{
        matcher: "Bash",
        hooks: [{
          type: "command",
          timeout: 5,
          command: ($home + "/.claude/hooks/block-dangerous-git.sh")
        }]
      }])
' > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"
echo "✓ merged personal keys into ${SETTINGS}"
