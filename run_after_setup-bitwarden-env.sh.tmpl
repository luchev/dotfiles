#!/usr/bin/env bash
# chezmoi: run_once_setup-bitwarden-env.sh
# Sync environment variables from Bitwarden to nushell config.
# This is sensitive infrastructure — only runs if the sync script exists.
set -euo pipefail

DOTFILES="${HOME}/.dotfiles"
SYNC_SCRIPT="${DOTFILES}/dot_config/nushell/sync-env-from-bitwarden.sh"

if [ -f "${SYNC_SCRIPT}" ]; then
    echo "Syncing env vars from Bitwarden..."
    bash "${SYNC_SCRIPT}" || echo "⚠ Bitwarden env sync failed (pinentry may be required)"
    echo "✓ Bitwarden env sync done"
else
    echo "  Bitwarden sync script not found at ${SYNC_SCRIPT}; skipping"
fi
