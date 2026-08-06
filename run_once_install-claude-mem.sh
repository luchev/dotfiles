#!/usr/bin/env bash
# chezmoi: run_once_install-claude-mem.sh
# Install claude-mem (shared memory store for Claude Code + opencode) and the
# cron job that keeps its gateway credential alive.
#
# claude-mem's worker runs on bun, and bun does not read the _auth line in
# ~/.npmrc — see dot_bunfig.toml. That config plus UNPM_USER / UNPM_PASS from
# ~/.config-local.nu is what lets `bun install` reach the Uber registry.
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

# The uSSO token is good for ~12h; refresh well inside that window. chezmoi
# apply also refreshes it (run_after_claude-mem-token.sh), but a machine can go
# days between applies.
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
