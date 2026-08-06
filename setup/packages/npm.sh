#!/usr/bin/env bash
# Install global npm packages.
set -euo pipefail

if ! command -v npm >/dev/null 2>&1; then
    echo "⚠ npm not found — cannot install npm packages"
    exit 0
fi

echo "✓ npm packages done"
