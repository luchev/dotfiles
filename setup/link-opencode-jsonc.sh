#!/usr/bin/env bash
# Link the right opencode.jsonc variant for this machine.
# Work machines (identified by ~/.dotfiles-work) omit the personal provider,
# model and skills blocks; everyone else gets the full personal config.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -e "${HOME}/.dotfiles-work" ]; then
    src="${REPO}/config/opencode/opencode.work.jsonc"
    label="work"
else
    src="${REPO}/config/opencode/opencode.jsonc"
    label="personal"
fi

mkdir -p "${HOME}/.config/opencode"
ln -sfn "$src" "${HOME}/.config/opencode/opencode.jsonc"
echo "✓ opencode.jsonc → ${label} variant"
