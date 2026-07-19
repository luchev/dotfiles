#!/usr/bin/env bash
# chezmoi: run_once_setup-integrations.sh
# Setup shell integrations: zoxide, atuin, pueue daemon, argc completions,
# gitconfig include, and local config stubs.
set -euo pipefail

DOTFILES="${HOME}/.dotfiles"

# ── Zoxide nushell init ────────────────────────────────────────────────────
if [ ! -f "${HOME}/.zoxide.nu" ]; then
    echo "Setting up zoxide nushell integration..."
    zoxide init nushell > "${HOME}/.zoxide.nu"
else
    echo "✓ zoxide.nu already exists"
fi

# ── Atuin nushell init ─────────────────────────────────────────────────────
if [ ! -f "${HOME}/.local/share/atuin/init.nu" ]; then
    echo "Setting up atuin nushell integration..."
    mkdir -p "${HOME}/.local/share/atuin"
    atuin init --disable-up-arrow nu > "${HOME}/.local/share/atuin/init.nu"
else
    echo "✓ atuin init.nu already exists"
fi

# ── Pueue daemon (systemd systems only) ────────────────────────────────────
if command -v pueued >/dev/null 2>&1 && command -v systemctl >/dev/null 2>&1; then
    echo "Setting up pueue daemon..."
    systemctl --user enable pueued 2>/dev/null || true
    systemctl --user start pueued 2>/dev/null || true
else
    echo "  Skipping pueue daemon (systemctl or pueued not available)"
fi

# ── argc-completions tools ─────────────────────────────────────────────────
if [ -d "${DOTFILES}/argc-completions" ]; then
    echo "Downloading argc tools..."
    (cd "${DOTFILES}/argc-completions" && ./scripts/download-tools.sh --force 2>/dev/null) ||
        echo "⚠ argc tools download failed (non-fatal)"
else
    echo "⚠ argc-completions directory not found; skipping tool download"
fi

# ── argc completions for nushell ───────────────────────────────────────────
ARG_BIN="${DOTFILES}/argc-completions/bin/argc"
if command -v "${ARG_BIN}" >/dev/null 2>&1; then
    echo "Generating argc completions for nushell..."
    mkdir -p "${DOTFILES}/argc-completions/tmp"
    "${ARG_BIN}" --argc-completions nushell > "${DOTFILES}/argc-completions/tmp/argc-completions.nu" 2>/dev/null ||
        echo "⚠ argc completions generation failed"
else
    echo "  Skipping argc completions (argc binary not found)"
fi

# ── Global gitconfig include (chezmoi manages ~/.gitconfig directly now; this
#    is a safety net for systems where gitconfig was previously managed by dotbot) ──
if [ -f "${HOME}/.gitconfig" ] && [ ! -L "${HOME}/.gitconfig" ]; then
    if ! grep -q 'chezmoi\|\.local/share/chezmoi' "${HOME}/.gitconfig" 2>/dev/null; then
        echo "  Manual .gitconfig not managed by chezmoi; leaving as-is"
    fi
fi

# ── Local config stubs ─────────────────────────────────────────────────────
mkdir -p "${HOME}/.config/nushell"
touch "${HOME}/.config/nushell/local.nu" "${HOME}/.config/nushell/local-env.nu"
mkdir -p "${HOME}/Library/Application Support/nushell"
touch "${HOME}/Library/Application Support/nushell/local.nu" \
      "${HOME}/Library/Application Support/nushell/local-env.nu"

echo "✓ Integration setup done"
