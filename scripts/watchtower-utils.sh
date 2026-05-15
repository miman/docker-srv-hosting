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
    local WATCHTOWER_CONFIG_FILE="${HSC_CONFIG_DIR:-$HOME/.hsc}/watchtower_configs.yaml"
    
    local want_watchtower="null"
    
    # Try to read existing choice from config
    if [ -f "$WATCHTOWER_CONFIG_FILE" ]; then
        local current_choice=$(grep "^${project_name}:" "$WATCHTOWER_CONFIG_FILE" | sed -e "s/^${project_name}:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
        
        if [ -n "$current_choice" ] && [ "$current_choice" != "null" ]; then
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

    # Save to watchtower_configs.yaml
    if [ -n "$want_watchtower" ] && [ "$want_watchtower" != "null" ]; then
        mkdir -p "$(dirname "$WATCHTOWER_CONFIG_FILE")"
        if [ ! -f "$WATCHTOWER_CONFIG_FILE" ]; then
            touch "$WATCHTOWER_CONFIG_FILE"
        fi
        
        if grep -q "^${project_name}:" "$WATCHTOWER_CONFIG_FILE"; then
            local tmp=$(mktemp)
            sed "s|^${project_name}:.*|${project_name}: ${want_watchtower}|" "$WATCHTOWER_CONFIG_FILE" > "$tmp" && mv "$tmp" "$WATCHTOWER_CONFIG_FILE"
        else
            echo "${project_name}: ${want_watchtower}" >> "$WATCHTOWER_CONFIG_FILE"
        fi
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
