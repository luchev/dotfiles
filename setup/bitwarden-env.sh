#!/usr/bin/env bash
# Sync environment variables from Bitwarden into ~/.config-local.nu.
# Run via: BW_ENV_ITEM_UUID=<uuid> ./install --bitwarden
set -euo pipefail

SYNC_SCRIPT="${HOME}/.config/nushell/sync-env-from-bitwarden.sh"

if ! command -v bw >/dev/null 2>&1; then
    echo "bitwarden-cli (bw) is not installed; cannot sync env vars" >&2
    exit 1
fi

if [ -z "${BW_ENV_ITEM_UUID:-}" ]; then
    echo "BW_ENV_ITEM_UUID is not set; cannot locate the env item in Bitwarden" >&2
    exit 1
fi

if [ ! -f "${SYNC_SCRIPT}" ]; then
    echo "sync script missing: ${SYNC_SCRIPT}" >&2
    exit 1
fi

echo "Syncing env vars from Bitwarden..."
bash "${SYNC_SCRIPT}"
echo "✓ Bitwarden env sync done"
