#!/usr/bin/env bash
# Restore all SSH keys from Bitwarden. Run via: ./install --bitwarden
set -euo pipefail

SYNC_SCRIPT="${HOME}/.config/nushell/sync-ssh-from-bitwarden.sh"

if ! command -v bw >/dev/null 2>&1; then
    echo "bitwarden-cli (bw) is not installed; cannot restore SSH keys" >&2
    exit 1
fi

if [ ! -f "${SYNC_SCRIPT}" ]; then
    echo "sync script missing: ${SYNC_SCRIPT}" >&2
    exit 1
fi

echo "Restoring SSH keys from Bitwarden..."
bash "${SYNC_SCRIPT}"
echo "✓ Bitwarden SSH key sync done"
