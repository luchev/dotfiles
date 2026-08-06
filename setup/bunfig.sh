#!/usr/bin/env bash
# Generate ~/.bunfig.toml for an authenticated private npm registry.
#
# bun does not read the _auth line in ~/.npmrc, so `bun install` fails against
# an authenticated private registry while npm succeeds from the same file.
#
# Opt-in only: no-ops unless NPM_REGISTRY_URL is set at apply time:
#   NPM_REGISTRY_URL=https://registry.example.com/ ./install
# Credentials are interpolated by bun at runtime from $NPM_REGISTRY_USER /
# $NPM_REGISTRY_PASS (set in ~/.config-local.nu, untracked) — kept out of the
# file so nothing secret is written to disk here.
set -euo pipefail

[ -n "${NPM_REGISTRY_URL:-}" ] || { echo "skip bunfig (NPM_REGISTRY_URL unset)"; exit 0; }

cat > "${HOME}/.bunfig.toml" <<EOF
[install.registry]
url = "${NPM_REGISTRY_URL}"
username = "\$NPM_REGISTRY_USER"
password = "\$NPM_REGISTRY_PASS"
EOF
echo "✓ wrote ~/.bunfig.toml (registry ${NPM_REGISTRY_URL})"
