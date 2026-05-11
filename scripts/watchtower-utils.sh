#!/bin/bash

# Function to ask if Watchtower should manage the service
# This should be called from within a service directory
ask_watchtower_label() {
    # If docker-compose.yml or docker-compose.yaml doesn't exist, we aren't in a service directory
    local COMPOSE_FILE=""
    if [ -f "docker-compose.yml" ]; then
        COMPOSE_FILE="docker-compose.yml"
    elif [ -f "docker-compose.yaml" ]; then
        COMPOSE_FILE="docker-compose.yaml"
    else
        return 0
    fi

    # Determine project name (folder name)
    local project_name=$(basename "$(pwd)")
    
    # Path to the config file
    local CONFIG_FILE="${HSC_CONFIG_PATH:-$HOME/.hsc/config.json}"
    
    local want_watchtower="null"
    
    # Try to read existing choice from config
    if [ -f "$CONFIG_FILE" ] && command -v jq > /dev/null; then
        local current_choice=$(jq -r ".watchtower_configs[\"$project_name\"]" "$CONFIG_FILE" 2>/dev/null)
        
        if [ "$current_choice" != "null" ] && [ -n "$current_choice" ]; then
            # If we already have a choice, only re-ask if the flag was passed
            if [ "$HSC_ASK_WATCHTOWER" == "true" ]; then
                local status_str="DISABLED"
                [ "$current_choice" == "true" ] && status_str="ENABLED"
                
                echo ""
                read -p "Watchtower is currently ${status_str} for '${project_name}'. Do you want to change this? (y/N) " change_answer
                if [[ "$change_answer" =~ ^[Yy]$ ]]; then
                    read -p "Do you want Watchtower to automatically update '${project_name}'? (y/N) " answer
                    if [[ "$answer" =~ ^[Yy]$ ]]; then
                        want_watchtower="true"
                    else
                        want_watchtower="false"
                    fi
                else
                    want_watchtower="$current_choice"
                fi
            else
                # Default behavior: use the existing choice without asking
                want_watchtower="$current_choice"
            fi
        fi
    fi

    # If no choice yet (not in config or file missing), ask the question
    if [ "$want_watchtower" == "null" ]; then
        echo ""
        read -p "Do you want Watchtower to automatically update '${project_name}'? (y/N) " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            want_watchtower="true"
        else
            want_watchtower="false"
        fi
    fi

    # Save to config.json
    if [ -f "$CONFIG_FILE" ] && command -v jq > /dev/null; then
        # Ensure watchtower_configs object exists
        if ! jq -e '.watchtower_configs' "$CONFIG_FILE" >/dev/null 2>&1; then
            local tmp=$(mktemp)
            jq '. + {watchtower_configs: {}}' "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
        fi
        # Save the choice
        local tmp=$(mktemp)
        jq ".watchtower_configs[\"$project_name\"] = $want_watchtower" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
    fi

    if [ "$want_watchtower" == "true" ]; then
        echo "Enabling Watchtower for ${project_name}..."
        
        # Try to find the first service name in the compose file
        # Matches lines starting with whitespace followed by a word and a colon
        local main_service=$(grep -m 1 "^[[:space:]]\+[a-zA-Z0-9_-]\+:" "$COMPOSE_FILE" | sed 's/^[[:space:]]\+//;s/://')
        
        if [ -z "$main_service" ]; then
            main_service="$project_name"
        fi

        local OVERRIDE_FILE="docker-compose.override.yml"
        [ -f "docker-compose.override.yaml" ] && OVERRIDE_FILE="docker-compose.override.yaml"

        cat > "$OVERRIDE_FILE" <<EOF
services:
  ${main_service}:
    labels:
      - com.centurylinklabs.watchtower.enable=true
EOF
        echo "Created $OVERRIDE_FILE with Watchtower label."
    else
        echo "Watchtower will not manage ${project_name}."
        rm -f "docker-compose.override.yml" "docker-compose.override.yaml" 2>/dev/null
    fi
}
