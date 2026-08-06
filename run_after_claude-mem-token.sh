#!/usr/bin/env bash
# chezmoi: run_after_claude-mem-token.sh
# Provision the claude-mem gateway credential after every apply.
#
# This is what makes a fresh machine work: the token cannot live in this repo
# (public, and it is short-lived), so it is minted at apply time instead. The
# refresh script no-ops without ~/.config/claude-mem-gateway.conf.
set -euo pipefail

REFRESH="${HOME}/bin/claude-mem-refresh-token.sh"

if [ -x "$REFRESH" ]; then
    "$REFRESH" || echo "⚠ claude-mem token refresh failed; run ${REFRESH} after re-authenticating" >&2
fi
