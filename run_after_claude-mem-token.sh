#!/usr/bin/env bash
# chezmoi: run_after_claude-mem-token.sh
# Provision the claude-mem gateway credential after every apply.
#
# This is what makes a fresh machine work: the token cannot live in this repo
# (public, and it expires ~daily), so it is minted at apply time instead.
# The refresh script no-ops when claude-mem or the uSSO helper is absent.
set -euo pipefail

REFRESH="${HOME}/bin/claude-mem-refresh-token.sh"

if [ -x "$REFRESH" ]; then
    "$REFRESH" || echo "⚠ claude-mem token refresh failed; run ${REFRESH} after uSSO auth" >&2
fi
