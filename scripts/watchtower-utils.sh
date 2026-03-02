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
    
    # Check if a container for this project is already running or exists
    # We check for containers that match the project name exactly or prefixed (project-service-1)
    if docker ps -a --format '{{.Names}}' | grep -q -E "^(${project_name}|${project_name}-)"; then
        return 0
    fi

    echo ""
    read -p "Do you want Watchtower to automatically update '${project_name}'? (y/N) " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Enabling Watchtower for ${project_name}..."
        
        # Create docker-compose.override.yml
        # Note: We assume the main service in the compose file has a name related to the project
        # or we just apply it to all services defined in the override.
        # However, a simpler override that targets the expected service name is better.
        # For now, we will create a generic override that the user might need to adjust 
        # but usually the service name matches the folder name or is common.
        
        # Try to find the first service name in the compose file
        local main_service=$(grep -m 1 "^  [a-zA-Z0-9_-]\+:" "$COMPOSE_FILE" | sed 's/  //;s/://')
        
        if [ -z "$main_service" ]; then
            # Fallback to project name if we can't parse one
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
    fi
}
