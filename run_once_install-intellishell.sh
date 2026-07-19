#!/usr/bin/env bash
# chezmoi: run_once_install-intellishell.sh
# Install intelli-shell (AI-powered command suggestions) and configure it.
set -euo pipefail

DOTFILES="${HOME}/.dotfiles"

# ── Install intelli-shell ──────────────────────────────────────────────────
INTELLI_BIN_DIR=""
if command -v intelli-shell >/dev/null 2>&1; then
    echo "✓ intelli-shell already installed"
    INTELLI_BIN_DIR="$(dirname "$(command -v intelli-shell)")"
elif [ -x "${HOME}/Library/Application Support/org.IntelliShell.Intelli-Shell/bin/intelli-shell" ]; then
    INTELLI_BIN_DIR="${HOME}/Library/Application Support/org.IntelliShell.Intelli-Shell/bin"
    echo "✓ intelli-shell already installed (macOS path)"
else
    echo "Installing intelli-shell..."
    curl -sSf https://raw.githubusercontent.com/lasantosr/intelli-shell/main/install.sh | INTELLI_SKIP_PROFILE=1 sh
    if [ -x "${HOME}/Library/Application Support/org.IntelliShell.Intelli-Shell/bin/intelli-shell" ]; then
        INTELLI_BIN_DIR="${HOME}/Library/Application Support/org.IntelliShell.Intelli-Shell/bin"
    fi
fi

if [ -n "${INTELLI_BIN_DIR:-}" ] && [ -d "$INTELLI_BIN_DIR" ]; then
    export PATH="${INTELLI_BIN_DIR}:${PATH}"
fi

# ── Fetch tldr data ────────────────────────────────────────────────────────
if command -v intelli-shell >/dev/null 2>&1; then
    intelli-shell tldr fetch 2>/dev/null || echo "⚠ tldr fetch failed (non-fatal)"
else
    echo "⚠ Skipping tldr fetch (intelli-shell not found in PATH)"
fi

# ── Restore backup if exists ───────────────────────────────────────────────
if command -v intelli-shell >/dev/null 2>&1; then
    if [ -f "${DOTFILES}/backups/intelli-shell-user-commands.txt" ]; then
        intelli-shell import --file "${DOTFILES}/backups/intelli-shell-user-commands.txt" 2>/dev/null ||
            echo "⚠ intelli-shell backup restore failed (non-fatal)"
    else
        echo "  No intelli-shell backup to restore"
    fi
else
    echo "  Skipping backup restore (intelli-shell not in PATH)"
fi

# ── Fix nushell compatibility ──────────────────────────────────────────────
INTELLI_NU="${HOME}/.local/share/nushell/vendor/autoload/intelli-shell.nu"
if [ -f "$INTELLI_NU" ]; then
    # Fix incompatibility with newer nushell versions
    sed -i '' 's/commandline edit --replace \$command_out --accept/commandline edit --replace $command_out/' "$INTELLI_NU" 2>/dev/null || true
fi

echo "✓ intelli-shell setup done"
