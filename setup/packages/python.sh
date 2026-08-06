#!/usr/bin/env bash
# Install Python-based CLI tools (thefuck, headroom).
set -euo pipefail

# thefuck
if command -v thefuck >/dev/null 2>&1; then
    echo "✓ thefuck already installed"
elif command -v pipx >/dev/null 2>&1; then
    echo "Installing thefuck..."
    pipx install thefuck
elif command -v apt-get >/dev/null 2>&1; then
    echo "Installing thefuck..."
    sudo apt-get update && sudo apt-get install -y python3-thefuck
else
    echo "Installing thefuck..."
    pip install thefuck --user --break-system-packages 2>/dev/null ||
        echo "⚠ Skipping thefuck (could not install)"
fi

# headroom — context compression proxy for coding agents
if command -v headroom >/dev/null 2>&1; then
    echo "✓ headroom already installed"
elif command -v uv >/dev/null 2>&1; then
    echo "Installing headroom..."
    uv tool install --python 3.13 "headroom-ai[all]"
else
    echo "⚠ Skipping headroom (uv not found)"
fi

# graphify — codebase knowledge graph. PyPI name is graphifyy (double y) while
# upstream reclaims "graphify"; the CLI is still `graphify`.
# `graphify install` regenerates ~/.config/opencode/skills/graphify/, which is
# deliberately not tracked in this repo.
if command -v graphify >/dev/null 2>&1; then
    echo "✓ graphify already installed"
elif command -v uv >/dev/null 2>&1; then
    echo "Installing graphify..."
    uv tool install graphifyy
    graphify install --platform claude
    graphify install --platform opencode
else
    echo "⚠ Skipping graphify (uv not found)"
fi

echo "✓ Python packages done"
