#!/usr/bin/env bash
# Cross-symlinks that point ~/.claude entries at the opencode config, so Claude
# Code and opencode share one instructions file and one skills tree.
# These target paths outside the repo, so dotbot's link: cannot express them.
set -euo pipefail

mkdir -p "${HOME}/.claude"
ln -sfn "${HOME}/.config/opencode/instructions.md" "${HOME}/.claude/CLAUDE.md"
ln -sfn "${HOME}/.config/opencode/skills"          "${HOME}/.claude/skills"
echo "✓ claude cross-symlinks (CLAUDE.md, skills) → opencode"
