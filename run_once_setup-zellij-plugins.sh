#!/usr/bin/env bash
# chezmoi: run_once_setup-zellij-plugins.sh
# Download zjstatus and zjstatus-hints plugins for Zellij,
# create the plugin dir and permission cache so they work out of the box
# with locked mode.
set -euo pipefail

PLUGIN_DIR="${HOME}/.config/zellij/plugins"
CACHE_DIR="${HOME}/Library/Caches/org.Zellij-Contributors.Zellij"
ZJSTATUS_URL="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm"
ZJSTATUS_HINTS_URL="https://github.com/b0o/zjstatus-hints/releases/latest/download/zjstatus-hints.wasm"

mkdir -p "$PLUGIN_DIR"
mkdir -p "$CACHE_DIR"

# Download zjstatus.wasm if missing
if [ ! -f "${PLUGIN_DIR}/zjstatus.wasm" ]; then
    echo "↓ Downloading zjstatus.wasm..."
    curl -fsSL "$ZJSTATUS_URL" -o "${PLUGIN_DIR}/zjstatus.wasm"
    if file "${PLUGIN_DIR}/zjstatus.wasm" | grep -q WebAssembly; then
        echo "✓ zjstatus.wasm installed ($(du -h "${PLUGIN_DIR}/zjstatus.wasm" | cut -f1))"
    else
        echo "✗ Downloaded zjstatus.wasm is not valid WebAssembly"
        exit 1
    fi
else
    echo "✓ zjstatus.wasm already present"
fi

# Download zjstatus-hints.wasm if missing
if [ ! -f "${PLUGIN_DIR}/zjstatus-hints.wasm" ]; then
    echo "↓ Downloading zjstatus-hints.wasm..."
    curl -fsSL "$ZJSTATUS_HINTS_URL" -o "${PLUGIN_DIR}/zjstatus-hints.wasm"
    if file "${PLUGIN_DIR}/zjstatus-hints.wasm" | grep -q WebAssembly; then
        echo "✓ zjstatus-hints.wasm installed ($(du -h "${PLUGIN_DIR}/zjstatus-hints.wasm" | cut -f1))"
    else
        echo "✗ Downloaded zjstatus-hints.wasm is not valid WebAssembly"
        exit 1
    fi
else
    echo "✓ zjstatus-hints.wasm already present"
fi

# Create permission cache for locked-mode compatibility.
# Key format is the raw absolute path (no "file:" prefix) because
# RunPluginLocation::File(path).to_string() produces just the path.
PERMISSION_FILE="${CACHE_DIR}/permissions.kdl"
if [ ! -f "$PERMISSION_FILE" ]; then
    cat > "$PERMISSION_FILE" << PERMS
"${HOME}/.config/zellij/plugins/zjstatus.wasm" {
    ReadApplicationState
    ChangeApplicationState
    RunCommands
}
"${HOME}/.config/zellij/plugins/zjstatus-hints.wasm" {
    ReadApplicationState
    ChangeApplicationState
    RunCommands
}
PERMS
    echo "✓ permission cache created at $PERMISSION_FILE"
else
    echo "✓ permission cache already exists at $PERMISSION_FILE"
fi
