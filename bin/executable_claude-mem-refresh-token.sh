#!/usr/bin/env bash
# Refresh the claude-mem LLM gateway credential.
#
# claude-mem's worker compresses every captured observation through an LLM, and
# those generated fields are the only ones its vector index embeds. An expired
# credential does not merely cost summaries — new observations silently become
# unsearchable while still reporting success.
#
# The worker blocks inherited ANTHROPIC_* vars and reads only
# ~/.claude-mem/.env, so it cannot reuse the host agent's credential helper.
# The token has to be written into that file.
#
# Gateway details are host-specific and deliberately not in this repo. Provide
# them in an untracked config file:
#
#   ~/.config/claude-mem-gateway.conf
#     TOKEN_HELPER=/path/to/helper      # prints a bearer token on stdout
#     GATEWAY_URL=https://your-gateway  # Anthropic-compatible base URL
#
# Without that file this script does nothing, which is the correct behaviour on
# a host that has no gateway.
set -euo pipefail

CONF="${HOME}/.config/claude-mem-gateway.conf"
ENV_FILE="${HOME}/.claude-mem/.env"

[ -d "${HOME}/.claude-mem" ] || { echo "claude-mem not installed; nothing to refresh"; exit 0; }
[ -f "$CONF" ] || { echo "no ${CONF}; skipping token refresh"; exit 0; }

# shellcheck source=/dev/null
. "$CONF"

if [ -z "${TOKEN_HELPER:-}" ] || [ -z "${GATEWAY_URL:-}" ]; then
    echo "⚠ ${CONF} must set TOKEN_HELPER and GATEWAY_URL" >&2
    exit 1
fi

if [ ! -x "$TOKEN_HELPER" ]; then
    echo "⚠ token helper not executable: ${TOKEN_HELPER}" >&2
    exit 1
fi

# Failing here is expected once the host's SSO session lapses. Say so rather
# than writing an empty token, which would look configured while silently
# failing every request.
if ! TOKEN=$("$TOKEN_HELPER" 2>/dev/null) || [ -z "$TOKEN" ]; then
    echo "⚠ token helper produced no token — re-authenticate, then rerun" >&2
    exit 1
fi

umask 077
printf 'ANTHROPIC_BASE_URL=%s\nANTHROPIC_AUTH_TOKEN=%s\n' "$GATEWAY_URL" "$TOKEN" > "$ENV_FILE"
chmod 600 "$ENV_FILE"

# Only bounce the worker if it is already up — starting one here would spawn a
# background daemon as a side effect of a config refresh.
if curl -fsS -m 3 "http://127.0.0.1:37700/health" >/dev/null 2>&1; then
    npx --yes claude-mem restart >/dev/null 2>&1 || true
    echo "✓ claude-mem token refreshed, worker restarted"
else
    echo "✓ claude-mem token refreshed (worker not running)"
fi
