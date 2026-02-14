#!/usr/bin/env bash
# Install Claude Code agents

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$HOME/.claude/agents"
SOURCE_DIR="$SCRIPT_DIR/claude/agents"

mkdir -p "$AGENTS_DIR"

if [ -d "$SOURCE_DIR" ]; then
    cp "$SOURCE_DIR"/*.md "$AGENTS_DIR/" 2>/dev/null
    count=$(ls -1 "$SOURCE_DIR"/*.md 2>/dev/null | wc -l)
    echo "✓ Installed $count Claude agents"
else
    echo "⚠ Skipping agents (source directory not found)"
fi
