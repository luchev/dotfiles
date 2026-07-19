#!/usr/bin/env bash
# chezmoi: run_once_install-cargo-pkgs.sh
# Install all cargo packages from the old dotbot setup.
# Split into individual cargo install calls so a failure in one
# doesn't abort the others.
set -euo pipefail

# Ensure cargo is available
CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}"

# Source env file if it exists
if [ -f "${CARGO_HOME}/env" ]; then
    # shellcheck source=~/.cargo/env
    . "${CARGO_HOME}/env"
fi

# Also check brew rustup proxy dir
BREW_RUSTUP_BIN="/opt/homebrew/opt/rustup/bin"
if ! command -v cargo >/dev/null 2>&1 && [ -d "$BREW_RUSTUP_BIN" ]; then
    export PATH="${BREW_RUSTUP_BIN}:${PATH}"
fi

# Final check
if ! command -v cargo >/dev/null 2>&1; then
    echo "⚠ cargo not found — cannot install packages"
    echo "  Ensure rustup is installed first (run_once_install-rust.sh)"
    exit 0
fi

echo "cargo version: $(cargo --version)"

install_crate() {
    local crate="$1"
    shift
    echo "  Installing ${crate}..."
    if cargo install "${crate}" "$@" 2>&1; then
        echo "    ✓ ${crate}"
    else
        echo "    ✗ ${crate} failed (continuing)"
    fi
}

echo "Installing cargo packages..."

install_crate fd-find
install_crate bat
install_crate ripgrep
install_crate starship
install_crate zoxide
install_crate eza
install_crate bottom
install_crate du-dust
install_crate just
install_crate trippy
install_crate pueue
install_crate gitui
install_crate bandwhich
install_crate procs
install_crate navi
install_crate tlrc
install_crate git-delta
install_crate tree-sitter-cli

# atuin: --locked pins build-time deps (needed to avoid broken transitive build)
install_crate atuin --locked

# tfil: PTY proxy for Ghostty cursor shader animation; author recommends --locked
install_crate tfil --locked

# yazi: uses yazi-build helper crate (direct cargo install panics). --force required.
install_crate yazi-build --locked --force

echo "✓ Cargo packages done"
