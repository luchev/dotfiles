#!/usr/bin/env bash
# chezmoi: run_once_install-git-addons.sh
# Install git addons: git-secrets, git-extras, git-stats, commitizen.
set -euo pipefail

DOTFILES="${HOME}/.dotfiles"

# ── git-secrets ────────────────────────────────────────────────────────────
if ! command -v git-secrets >/dev/null 2>&1; then
    echo "Installing git-secrets..."
    TMPDIR="$(mktemp -d)"
    git clone https://github.com/awslabs/git-secrets "${TMPDIR}/git-secrets"
    (cd "${TMPDIR}/git-secrets" && make install PREFIX="${HOME}/.local")
    rm -rf "${TMPDIR}"

    # Global git-secrets config
    if [ ! -d "${HOME}/.git-templates/git-secrets" ]; then
        git secrets --register-aws --global 2>/dev/null || true
        mkdir -p "${HOME}/.git-templates/git-secrets"
        git secrets --install "${HOME}/.git-templates/git-secrets" 2>/dev/null || true
        git config --global init.templateDir "${HOME}/.git-templates/git-secrets"
    fi

    # Install hooks in dotfiles repo
    (cd "${DOTFILES}" && git secrets --install 2>/dev/null || true && git secrets --register-aws 2>/dev/null || true)
else
    echo "✓ git-secrets already installed"
fi

# ── git-extras ─────────────────────────────────────────────────────────────
if ! command -v git-summary >/dev/null 2>&1; then
    echo "Installing git-extras..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y git-extras
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm git-extras
    elif command -v brew >/dev/null 2>&1; then
        brew install git-extras
    else
        echo "⚠ Skipping git-extras (no supported package manager)"
    fi
else
    echo "✓ git-extras already installed"
fi

# ── git-stats (npm) ────────────────────────────────────────────────────────
if command -v npm >/dev/null 2>&1; then
    if npm list -g git-stats >/dev/null 2>&1; then
        echo "✓ git-stats already installed"
    else
        echo "Installing git-stats..."
        npm install -g git-stats
    fi
else
    echo "⚠ Skipping git-stats (npm not found)"
fi

# ── commitizen (npm) ───────────────────────────────────────────────────────
if command -v npm >/dev/null 2>&1; then
    if npm list -g commitizen >/dev/null 2>&1; then
        echo "✓ commitizen already installed"
    else
        echo "Installing commitizen..."
        npm install -g commitizen cz-conventional-changelog
    fi
else
    echo "⚠ Skipping commitizen (npm not found)"
fi

echo "✓ Git addons done"
