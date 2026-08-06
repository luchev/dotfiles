#!/bin/bash

# Ensure BW_ENV_ITEM_UUID is set
if [ -z "$BW_ENV_ITEM_UUID" ]; then
    echo "Error: BW_ENV_ITEM_UUID is not set."
    exit 1
fi

# Sync Bitwarden
echo "Syncing Bitwarden..."
bw sync

ENV_FILE="$HOME/.config-local.nu"
touch "$ENV_FILE"

# Fetch notes, replace literal \n with actual newlines
NOTES=$(bw get item "$BW_ENV_ITEM_UUID" | jq -r '.notes // ""' | sed 's/\\n/\n/g')

# Process lines
echo "$NOTES" | while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue
    
    # Extract KEY and VALUE (format: $env.KEY = value)
    # Using sed to remove '$env.' and split by '='
    # Example: $env.DEEPSEEK_API_KEY = \"sk-key\" -> DEEPSEEK_API_KEY = \"sk-key\"
    
    CLEAN_LINE=$(echo "$line" | sed 's/^\$env\.//')
    
    if [[ "$CLEAN_LINE" =~ ^([a-zA-Z0-9_]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
        KEY="${BASH_REMATCH[1]}"
        VALUE="${BASH_REMATCH[2]}"
        
        # Removed quote-stripping sed here to preserve quotes in value
        
        ENTRY="\$env.$KEY = $VALUE"
        
        # Check if exists
        if grep -q "\$env.$KEY =" "$ENV_FILE"; then
            # Update
            sed -i '' "s|.*\$env.$KEY =.*|$ENTRY|" "$ENV_FILE"
            echo "Updated: $KEY"
        else
            # Append
            echo "$ENTRY" >> "$ENV_FILE"
            echo "Added: $KEY"
        fi
    fi
done

echo "Sync complete."
