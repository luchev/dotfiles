#!/bin/bash
# Restore ALL SSH keys from Bitwarden SSH Key items (type 5).
# Iterates every SSH key item in the vault and writes to ~/.ssh/<name>.

set -euo pipefail

SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

echo "Fetching all SSH keys from Bitwarden..."

bw list items | jq -c '.[] | select(.type == 5) | {id, name, privateKey: .sshKey.privateKey, publicKey: .sshKey.publicKey}' | while IFS= read -r entry; do
    item_name=$(echo "$entry" | jq -r '.name')
    priv_key=$(echo "$entry" | jq -r '.privateKey // ""')
    pub_key=$(echo "$entry" | jq -r '.publicKey // ""')

    [ -z "$priv_key" ] && { echo "  Skipping '$item_name' (no private key)"; continue; }

    # Derive filename: "ssh hetzner" → "hetzner"
    file_name=$(echo "$item_name" \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/^ssh[ _-]*//' \
        | sed 's/[^a-zA-Z0-9._-]/_/g')
    [ -z "$file_name" ] && file_name=$(echo "$item_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9._-]/_/g')

    priv_path="$SSH_DIR/$file_name"
    echo "$priv_key" > "$priv_path"
    chmod 600 "$priv_path"
    echo "  ✓ $priv_path"

    if [ -n "$pub_key" ]; then
        pub_path="$SSH_DIR/$file_name.pub"
        echo "$pub_key" > "$pub_path"
        chmod 644 "$pub_path"
        echo "  ✓ $pub_path"
    fi

    if [ -n "${SSH_AUTH_SOCK:-}" ]; then
        ssh-add "$priv_path" 2>/dev/null && echo "  ✓ Added to ssh-agent" || true
    fi
done

echo "Done."
