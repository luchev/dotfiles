#!/usr/bin/env bash
# chezmoi: run_once_install-brew-pkgs.sh
# Install essential CLI tools via the system package manager.
# Preserves the original dotbot multi-package-manager approach.
set -euo pipefail

PACKAGES="fzf jq yq direnv htop"

# Filter only missing packages
MISSING=""
for pkg in $PACKAGES; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
        MISSING="$MISSING $pkg"
    fi
done

if [ -z "$MISSING" ]; then
    echo "✓ All essential packages already installed"
    exit 0
fi

echo "Installing missing packages:${MISSING}"

if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y $MISSING
elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm $MISSING
elif command -v brew >/dev/null 2>&1; then
    brew install $MISSING
else
    echo "⚠ No supported package manager found (apt-get, pacman, brew)"
    echo "  Missing packages:${MISSING}"
fi

echo "✓ Package installation complete"
