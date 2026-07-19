#!/usr/bin/env bash
# chezmoi: run_once_install-python-pkgs.sh
# Install Python-based CLI tools (thefuck).
set -euo pipefail

# thefuck
if command -v thefuck >/dev/null 2>&1; then
    echo "✓ thefuck already installed"
    exit 0
fi

echo "Installing thefuck..."
if command -v pipx >/dev/null 2>&1; then
    pipx install thefuck
elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y python3-thefuck
else
    pip install thefuck --user --break-system-packages 2>/dev/null ||
        echo "⚠ Skipping thefuck (could not install)"
fi

echo "✓ Python packages done"
