#!/usr/bin/env bash
# Refresh the claude-mem gateway credential.
#
# claude-mem's worker compresses every captured observation through an LLM, and
# that compression is what produces the narrative/facts/concepts fields. Those
# are the only fields the vector index embeds, so an expired token does not
# merely cost summaries — new observations become unsearchable while still
# reporting success.
#
# The worker deliberately blocks inherited ANTHROPIC_* vars and re-injects only
# what is in ~/.claude-mem/.env, so it cannot use Claude Code's apiKeyHelper.
# The token has to be written to that file. It is a uSSO JWT, good for ~12h.
#
# No-ops cleanly when the helper or claude-mem is absent, so this is safe to run
# on a machine that has neither.
set -euo pipefail

HELPER="${HOME}/.local/share/aifx/bin/claude-genai-token-helper"
ENV_FILE="${HOME}/.claude-mem/.env"
BASE_URL="https://gateway.internal.example"

if [ ! -d "${HOME}/.claude-mem" ]; then
    echo "claude-mem not installed; nothing to refresh"
    exit 0
fi

if [ ! -x "$HELPER" ]; then
    echo "⚠ token helper not found at ${HELPER} — claude-mem compression will fail" >&2
    echo "  (install aifx, or point claude-mem at a different provider)" >&2
    exit 0
fi

# The helper needs a live uSSO session. Failing here is expected after it
# lapses; say so rather than writing an empty token, which would look
# configured while silently failing every request.
if ! TOKEN=$("$HELPER" 2>/dev/null) || [ -z "$TOKEN" ]; then
    echo "⚠ token helper produced no token — re-authenticate uSSO, then rerun" >&2
    exit 1
fi

umask 077
printf 'ANTHROPIC_BASE_URL=%s\nANTHROPIC_AUTH_TOKEN=%s\n' "$BASE_URL" "$TOKEN" > "$ENV_FILE"
chmod 600 "$ENV_FILE"

# Only bounce the worker if it is already up — starting one here would spawn a
# background daemon as a side effect of a config refresh.
if curl -fsS -m 3 "http://127.0.0.1:37700/health" >/dev/null 2>&1; then
    npx --yes claude-mem restart >/dev/null 2>&1 || true
    echo "✓ claude-mem token refreshed, worker restarted"
else
    echo "✓ claude-mem token refreshed (worker not running)"
fi
