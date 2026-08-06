#!/usr/bin/env bash
# chezmoi: run_once_install-claude-mem.sh
# Install claude-mem (shared memory store for Claude Code + opencode) and the
# cron job that keeps its LLM gateway credential alive.
#
# claude-mem's worker runs on bun. If your npm registry requires auth, bun will
# not pick it up from ~/.npmrc — see dot_bunfig.toml.tmpl.
set -euo pipefail

if [ ! -d "${HOME}/.claude-mem" ]; then
    if command -v npx >/dev/null 2>&1; then
        echo "Installing claude-mem..."
        npx --yes claude-mem install --ide claude-code </dev/null
        npx --yes claude-mem install --ide opencode </dev/null
        # Telemetry is ON by default; memory content is not something to sample.
        npx --yes claude-mem telemetry disable </dev/null || true
    else
        echo "⚠ Skipping claude-mem (npx not found)"
    fi
else
    echo "✓ claude-mem already installed"
fi

# Gateway tokens are typically short-lived. chezmoi apply refreshes one
# (run_after_claude-mem-token.sh), but a machine can go days between applies.
# The refresh script no-ops unless a gateway config exists, so installing the
# cron job unconditionally is harmless.
REFRESH="${HOME}/bin/claude-mem-refresh-token.sh"
if command -v crontab >/dev/null 2>&1 && [ -x "$REFRESH" ]; then
    if crontab -l 2>/dev/null | grep -qF "claude-mem-refresh-token"; then
        echo "✓ claude-mem token cron already present"
    else
        # Offset from the hour: every host running this on :00 is a thundering herd.
        { crontab -l 2>/dev/null || true; echo "17 */6 * * * ${REFRESH} >/dev/null 2>&1"; } | crontab -
        echo "✓ claude-mem token cron installed (every 6h)"
    fi
fi

echo "✓ claude-mem setup done"
