#!/usr/bin/env bash
# chezmoi: run_once_install-rust.sh
# Install Rust toolchain if missing, set up proxy binaries, then update.
set -euo pipefail

# ── Install rustup if missing ──────────────────────────────────────────────
if ! command -v rustup >/dev/null 2>&1; then
    echo "Installing Rust toolchain..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    # shellcheck source=~/.cargo/env
    . "${HOME}/.cargo/env"
else
    echo "✓ rustup already installed"
fi

# ── Ensure cargo proxy binaries exist in ~/.cargo/bin/ ────────────────────
# When rustup is installed via Homebrew, only the `rustup` binary is linked
# into /opt/homebrew/bin/. The cargo/rustc/rustdoc proxy scripts live in
# /opt/homebrew/opt/rustup/bin/ but aren't linked, so they're not in PATH.
# We symlink them into ~/.cargo/bin/ (which IS in the user's PATH).
RUSTUP_BREW_BIN="/opt/homebrew/opt/rustup/bin"
CARGO_BIN="${CARGO_HOME:-${HOME}/.cargo}/bin"

if [ -d "$RUSTUP_BREW_BIN" ] && [ ! -x "${CARGO_BIN}/cargo" ]; then
    echo "Setting up rustup proxy binaries in ${CARGO_BIN}..."
    mkdir -p "${CARGO_BIN}"
    for tool in cargo cargo-clippy cargo-fmt cargo-miri clippy-driver \
                rls rust-analyzer rust-gdb rust-gdbgui rust-lldb \
                rustc rustdoc rustfmt; do
        if [ -f "${RUSTUP_BREW_BIN}/${tool}" ]; then
            ln -sf "${RUSTUP_BREW_BIN}/${tool}" "${CARGO_BIN}/${tool}"
        fi
    done
    echo "  Linked cargo/rustc/etc proxies into ${CARGO_BIN}"
elif [ -x "${CARGO_BIN}/cargo" ]; then
    echo "✓ cargo proxy already in ${CARGO_BIN}"
fi

# Ensure ~/.cargo/env exists (created by official installer, not by brew)
CARGO_ENV="${CARGO_HOME:-${HOME}/.cargo}/env"
if [ ! -f "$CARGO_ENV" ]; then
    echo "Creating ${CARGO_ENV}..."
    mkdir -p "$(dirname "$CARGO_ENV")"
    cat > "$CARGO_ENV" <<-'EOF'
# rustup/cargo environment (chezmoi-managed)
CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}"
case ":${PATH}:" in
    *:"${CARGO_HOME}/bin":*) ;;
    *) export PATH="${CARGO_HOME}/bin:${PATH}" ;;
esac
EOF
fi

# ── Update to latest stable ────────────────────────────────────────────────
export CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}"
export PATH="${CARGO_HOME}/bin:${PATH}"
rustup update stable

echo "✓ Rust toolchain is ready"
