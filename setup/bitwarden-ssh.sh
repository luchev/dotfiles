#!/usr/bin/env bash
# Restore all SSH keys from Bitwarden.
#
# Opt-in only: no-ops unless DOTBOT_BITWARDEN is set.
#   DOTBOT_BITWARDEN=1 ./install
set -euo pipefail

[ -n "${DOTBOT_BITWARDEN:-}" ] || { echo "skip Bitwarden SSH (set DOTBOT_BITWARDEN=1)"; exit 0; }

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
