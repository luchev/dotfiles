#!/usr/bin/env bash
# chezmoi: run_once_install-impeccable.sh
# Install impeccable (frontend design language + anti-pattern detector) for
# Claude Code and opencode.
#
# Two upstream behaviours this works around:
#
#  1. `impeccable install --help` RUNS the install rather than printing help,
#     taking defaults non-interactively. Do not probe its flags.
#  2. The installer targets every harness it detects — cursor, gemini, a
#     $HOME-scoped .opencode — at ~3.3M per copy. Only the shared skills dir is
#     wanted, so the rest are pruned afterwards rather than prevented, which
#     keeps this independent of undocumented flags.
#
# ~/.claude/skills is a symlink to ~/.config/opencode/skills, so one copy there
# serves both agents. The generated dir is chezmoi-ignored and reinstalled here.
set -euo pipefail

SKILL_DIR="${HOME}/.config/opencode/skills/impeccable"

if [ -d "$SKILL_DIR" ]; then
    echo "✓ impeccable already installed"
    exit 0
fi

if ! command -v npx >/dev/null 2>&1; then
    echo "⚠ Skipping impeccable (npx not found)"
    exit 0
fi

echo "Installing impeccable..."
(cd "$HOME" && npx --yes impeccable install </dev/null)

# The installer may route the real directory into a work dotfiles checkout via
# a symlink. Materialise it in the shared skills dir so this machine does not
# depend on that checkout being present.
if [ -L "$SKILL_DIR" ]; then
    target=$(readlink -f "$SKILL_DIR")
    rm "$SKILL_DIR"
    [ -d "$target" ] && mv "$target" "$SKILL_DIR"
fi

# Prune harnesses that are not in use.
rm -rf "${HOME}/.cursor/skills/impeccable" \
       "${HOME}/.gemini/skills/impeccable" \
       "${HOME}/.opencode/skills/impeccable"

if [ -d "$SKILL_DIR" ]; then
    echo "✓ impeccable installed for Claude Code + opencode"
else
    echo "⚠ impeccable install did not produce ${SKILL_DIR}" >&2
fi
