#!/usr/bin/env bash
# PreToolUse hook: refuse the destructive git/chezmoi invocations that
# instructions.md already bans in prose. Prose is advisory; this is not.
#
# Exit 0 = allow, exit 2 = block with the stderr text shown to Claude.
# Any internal failure allows the command: a broken guardrail must never
# wedge the session.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

cmd=$(jq -r 'select(.tool_name == "Bash") | .tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

# Strip heredoc bodies and quoted spans before matching. Commit messages and
# PR bodies legitimately discuss --force; only real argv should be scanned.
scan=$(printf '%s\n' "$cmd" | awk '
  $0 ~ /<<-?[A-Za-z_"'"'"']/ {
    delim = $0
    sub(/^.*<<-?/, "", delim)
    gsub(/["'"'"']/, "", delim)
    sub(/[^A-Za-z0-9_].*$/, "", delim)
    print; skip = delim; next
  }
  skip != "" { if ($0 == skip) skip = ""; next }
  { print }
' | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")

deny() {
  printf 'Blocked by block-dangerous-git hook.\n\n%s\n\n%s\n' "$1" \
    'This is banned in ~/.claude/rules. If it is genuinely the only option, explain why and let the user run it themselves.' >&2
  exit 2
}

# --force-with-lease is the sanctioned form, so exclude it: the [^-] guard
# stops --force matching the --force-with-lease prefix.
if printf '%s' "$scan" | grep -Eq 'git([^;&|]*)\bpush\b'; then
  if printf '%s' "$scan" | grep -Eq '\-\-force([^-]|$)'; then
    deny 'Bare "git push --force" overwrites remote history unconditionally. Use --force-with-lease, which refuses when the remote has moved.'
  fi
  if printf '%s' "$scan" | grep -Eq '(^| )-f( |$)'; then
    deny 'Bare "git push -f" overwrites remote history unconditionally. Use --force-with-lease.'
  fi
fi

printf '%s' "$scan" | grep -Eq 'git[^;&|]*\breset\b[^;&|]*--hard' \
  && deny '"git reset --hard" discards uncommitted work with no recovery path. Stash it or commit it first.'

printf '%s' "$scan" | grep -Eq 'git[^;&|]*\bclean\b[^;&|]*(^| )-[a-eg-z]*f' \
  && deny '"git clean -f" deletes untracked files irrecoverably. Run it with -n first and show the user what would go.'

printf '%s' "$scan" | grep -Eq 'git[^;&|]*\bbranch\b[^;&|]*(^| )-D' \
  && deny '"git branch -D" force-deletes a branch that may hold unmerged commits. Use -d, and diagnose if it refuses.'

printf '%s' "$scan" | grep -Eq 'git[^;&|]*\bcheckout\b[^;&|]*((^| )-f|( )\.( |$))' \
  && deny '"git checkout -f" / "git checkout ." silently discards working-tree changes.'

printf '%s' "$scan" | grep -Eq 'git[^;&|]*\brestore\b[^;&|]*( )\.( |$)' \
  && deny '"git restore ." silently discards every unstaged change in the tree.'

printf '%s' "$scan" | grep -Eq 'git[^;&|]*\bworktree\b[^;&|]*remove[^;&|]*--force' \
  && deny '"git worktree remove --force" discards a dirty worktree. A remove that needs --force means unaccounted state — diagnose it.'

printf '%s' "$scan" | grep -Eq 'chezmoi[^;&|]*(apply|update)[^;&|]*(--force|(^| )-f( |$))' \
  && deny '"chezmoi apply --force" overwrites local modifications without showing them. Run "chezmoi diff" and resolve the conflict.'

exit 0
