#!/usr/bin/env bash
# chezmoi: run_once_setup-bitwarden-ssh.sh
# Restore all SSH keys from Bitwarden on first chezmoi apply.
set -euo pipefail

DOTFILES="${HOME}/.dotfiles"
SYNC_SCRIPT="${DOTFILES}/dot_config/nushell/sync-ssh-from-bitwarden.sh"

if [ -f "${SYNC_SCRIPT}" ]; then
    echo "Restoring SSH keys from Bitwarden..."
    bash "${SYNC_SCRIPT}" || echo "⚠ Bitwarden SSH key sync failed (pinentry may be required)"
    echo "✓ Bitwarden SSH key sync done"
else
    echo "  Bitwarden SSH sync script not found; skipping"
fi
