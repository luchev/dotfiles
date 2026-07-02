# Simplified script to set BW_SESSION in ~/.env.nu

def main [] {
    print "--- Bitwarden Environment Setup ---"
    print "Please run: 'bw login' (or 'bw unlock' if already logged in)."
    print "Copy the resulting 'export BW_SESSION=...' token."
    
    let env_file = ("~/.env.nu" | path expand)
    
    # Helper to get existing value
    def get_existing [name] {
        if ($env_file | path exists) {
            let lines = (open $env_file | lines)
            let matches = ($lines | find $"$env.($name) =")
            if ($matches | is-not-empty) {
                # Attempt to extract value, handle potential parse errors
                let line = ($matches | first)
                try {
                    return ($line | parse $"$env.($name) = \"{val}\"" | get 0.val)
                } catch {
                    return ""
                }
            }
        }
        return ""
    }

    # BW_SESSION
    let current_token = (get_existing "BW_SESSION")
    let prompt_token = (if ($current_token | is-not-empty) { $"Paste new BW_SESSION (leave empty to keep current: '($current_token)'): " } else { "Paste BW_SESSION: " })
    let token = (input $prompt_token | str trim)
    
    # BW_ENV_ITEM_UUID
    let current_uuid = (get_existing "BW_ENV_ITEM_UUID")
    let prompt_uuid = (if ($current_uuid | is-not-empty) { $"Paste new BW_ENV_ITEM_UUID (leave empty to keep current: '($current_uuid)'): " } else { "Paste BW_ENV_ITEM_UUID: " })
    let uuid = (input $prompt_uuid | str trim)
    
    if ($token | is-not-empty) {
        save_env_var "BW_SESSION" $token $env_file
    }
    
    if ($uuid | is-not-empty) {
        save_env_var "BW_ENV_ITEM_UUID" $uuid $env_file
    }
}

def save_env_var [name: string, value: string, file: path] {
    # Escape double quotes for Nushell string literal
    let escaped_value = ($value | str replace --all '"' '\"')
    let entry = $"$env.($name) = \"($escaped_value)\""
    
    # Ensure file exists or create it
    if not ($file | path exists) {
        touch $file
    }
    
    let lines = (open $file | lines)
    let exists = ($lines | any { |l| $l | str contains $"$env.($name) =" })
        
    if $exists {
        let new_lines = ($lines | each { |l| 
            if ($l | str contains $"$env.($name) =") { 
                $entry 
            } else { 
                $l 
            } 
        })
        $new_lines | str join "\n" | save -f $file
    } else {
        ($lines | append $entry | str join "\n") | save -f $file
    }
    print $"Successfully saved ($name) to ($file)"
}
