#!/usr/bin/env bash
# chezmoi: run_always_gen-zellij-workspace.sh
# Generate .zellij-workspace listing all layout files.
set -euo pipefail

LAYOUTS_DIR="${HOME}/.config/zellij/layouts"
OUTPUT="${HOME}/.zellij-workspace"

if [ ! -d "$LAYOUTS_DIR" ]; then
    echo "skipped (no layouts dir)"
    exit 0
fi

# List all .kdl files, relative to home
ls -1 "$LAYOUTS_DIR"/*.kdl 2>/dev/null \
    | xargs -n1 basename \
    | sed 's/^/.config\/zellij\/layouts\//' \
    > "$OUTPUT"

echo "done ($(wc -l < "$OUTPUT") layouts)"
