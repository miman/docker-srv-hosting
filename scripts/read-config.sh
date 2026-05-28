#!/bin/bash

# Check if -askwatchtower flag is present in command line arguments
# This allows forcing a re-ask of the Watchtower preference for installed services.
for arg in "$@"; do
    if [[ "$arg" == "-askwatchtower" || "$arg" == "--askwatchtower" ]]; then
        export HSC_ASK_WATCHTOWER=true
        break
    fi
done
# This script ensures that the DOCKER_FOLDER environment variable is set.
# It first checks if the variable is already set. If not, it attempts to
# read it from the central configuration file ~/.hsc/config.yaml.
#
# This script is intended to be sourced by other scripts, e.g.:
# source scripts/read-config.sh

# Source Watchtower utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/watchtower-utils.sh" ]; then
    source "$SCRIPT_DIR/watchtower-utils.sh"
elif [ -f "$SCRIPT_DIR/scripts/watchtower-utils.sh" ]; then
    source "$SCRIPT_DIR/scripts/watchtower-utils.sh"
fi

# Define config file path
export HSC_CONFIG_PATH="${HSC_CONFIG_PATH:-$HOME/.hsc/config.yaml}"

# Check if DOCKER_FOLDER is set, otherwise read from config
if [ -z "$DOCKER_FOLDER" ]; then
    echo "DOCKER_FOLDER not set, attempting to read from $HSC_CONFIG_PATH"
    if [ -f "$HSC_CONFIG_PATH" ]; then
        DOCKER_FOLDER=$(grep "^docker_root:" "$HSC_CONFIG_PATH" | sed -e "s/^docker_root:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
        if [ -z "$DOCKER_FOLDER" ] || [ "$DOCKER_FOLDER" == "null" ]; then
            echo "Error: 'docker_root' not found or is null in $HSC_CONFIG_PATH." >&2
            exit 1
        fi
        echo "Successfully read DOCKER_FOLDER from config: $DOCKER_FOLDER"
    else
        echo "Error: DOCKER_FOLDER is not set and $HSC_CONFIG_PATH was not found." >&2
        exit 1
    fi
fi

# Export the variable so it's available to sub-processes like docker-compose
export DOCKER_FOLDER

# Detect Podman socket for rootless/rootful setups and export DOCKER_SOCK
if command -v podman &> /dev/null; then
    # Try to start/enable rootless user socket if using systemd and not active
    if ! systemctl --user is-active --quiet podman.socket 2>/dev/null; then
        systemctl --user enable --now podman.socket &>/dev/null || true
    fi

    # Set dynamic DOCKER_SOCK location
    if [ -n "$XDG_RUNTIME_DIR" ] && [ -S "$XDG_RUNTIME_DIR/podman/podman.sock" ]; then
        export DOCKER_SOCK="$XDG_RUNTIME_DIR/podman/podman.sock"
    elif [ -S "/run/user/$(id -u)/podman/podman.sock" ]; then
        export DOCKER_SOCK="/run/user/$(id -u)/podman/podman.sock"
    elif [ -S "/run/podman/podman.sock" ]; then
        export DOCKER_SOCK="/run/podman/podman.sock"
    fi
    
    # Set dynamic DOCKER_VOLUMES location
    if [ -d "$HOME/.local/share/containers/storage/volumes" ]; then
        export DOCKER_VOLUMES="$HOME/.local/share/containers/storage/volumes"
    elif [ -d "/var/lib/containers/storage/volumes" ]; then
        export DOCKER_VOLUMES="/var/lib/containers/storage/volumes"
    else
        # If directories don't exist yet (clean install), default based on root/rootless user
        if [ "$(id -u)" -ne 0 ]; then
            export DOCKER_VOLUMES="$HOME/.local/share/containers/storage/volumes"
        else
            export DOCKER_VOLUMES="/var/lib/containers/storage/volumes"
        fi
    fi
    
    echo "Podman detected."
    echo "  -> DOCKER_SOCK set to: ${DOCKER_SOCK:-Not Found}"
    echo "  -> DOCKER_VOLUMES set to: ${DOCKER_VOLUMES:-Not Found}"
fi

# Read and export BASE_DNS_NAME
if [ -z "$BASE_DNS_NAME" ]; then
    if [ -f "$HSC_CONFIG_PATH" ]; then
        BASE_DNS_NAME=$(grep "^base_dns_name:" "$HSC_CONFIG_PATH" | sed -e "s/^base_dns_name:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
        if [ -z "$BASE_DNS_NAME" ] || [ "$BASE_DNS_NAME" == "null" ]; then
            echo "Error: 'base_dns_name' not found or is null in $HSC_CONFIG_PATH." >&2
            exit 1
        fi
        echo "Successfully read BASE_DNS_NAME from config: $BASE_DNS_NAME"
    else
        echo "Error: BASE_DNS_NAME is not set and $HSC_CONFIG_PATH was not found." >&2
        exit 1
    fi
fi
export BASE_DNS_NAME

# Read and export EXTERNAL_DUCKDNS_NAME
if [ -z "$EXTERNAL_DUCKDNS_NAME" ]; then
    if [ -f "$HSC_CONFIG_PATH" ]; then
        EXTERNAL_DUCKDNS_NAME=$(grep "^external_duckdns_name:" "$HSC_CONFIG_PATH" | sed -e "s/^external_duckdns_name:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
        if [ "$EXTERNAL_DUCKDNS_NAME" == "null" ]; then
            EXTERNAL_DUCKDNS_NAME=""
        fi
    fi
fi
export EXTERNAL_DUCKDNS_NAME

# Read and export CONTAINER_ENGINE (docker or podman)
# This determines which container runtime commands to use throughout the project.
if [ -z "$CONTAINER_ENGINE" ]; then
    if [ -f "$HSC_CONFIG_PATH" ]; then
        CONTAINER_ENGINE=$(grep "^container_engine:" "$HSC_CONFIG_PATH" | sed -e "s/^container_engine:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
    fi

    if [ -z "$CONTAINER_ENGINE" ] || [ "$CONTAINER_ENGINE" == "null" ]; then
        echo ""
        echo "No container engine configured. Which container engine do you want to use?"
        echo "1) docker"
        echo "2) podman"
        read -p "Enter your choice [1-2]: " engine_choice
        case $engine_choice in
            1) CONTAINER_ENGINE="docker" ;;
            2) CONTAINER_ENGINE="podman" ;;
            *) echo "Invalid choice, defaulting to docker."; CONTAINER_ENGINE="docker" ;;
        esac
        # Save the choice to config
        mkdir -p "$(dirname "$HSC_CONFIG_PATH")"
        if [ ! -f "$HSC_CONFIG_PATH" ]; then
            echo "container_engine: \"${CONTAINER_ENGINE}\"" > "$HSC_CONFIG_PATH"
            chmod 600 "$HSC_CONFIG_PATH"
        elif grep -q "^container_engine:" "$HSC_CONFIG_PATH"; then
            _tmp_file=$(mktemp)
            sed "s|^container_engine:.*|container_engine: \"${CONTAINER_ENGINE}\"|" "$HSC_CONFIG_PATH" > "$_tmp_file" && mv "$_tmp_file" "$HSC_CONFIG_PATH"
        else
            echo "container_engine: \"${CONTAINER_ENGINE}\"" >> "$HSC_CONFIG_PATH"
        fi
        echo "Saved container engine preference: $CONTAINER_ENGINE"
    fi
fi
export CONTAINER_ENGINE

# Set the container command variables based on the chosen engine
if [ "$CONTAINER_ENGINE" == "podman" ]; then
    export CONTAINER_CMD="podman"
    export COMPOSE_CMD="podman compose"
    export RESTART_POLICY="always"
else
    export CONTAINER_CMD="docker"
    export COMPOSE_CMD="docker compose"
    export RESTART_POLICY="unless-stopped"
fi


# Helper function to set a value in config.yaml
# Usage: set_config_value "some_key" "some_value"
set_config_value() {
    local key=$1
    local value=$2
    local tmp_file=$(mktemp)
    
    # Strip leading dot for backward compatibility with old jq syntax
    key="${key#.}"
    
    # Ensure config directory exists
    mkdir -p "$(dirname "$HSC_CONFIG_PATH")"
    
    if [ ! -f "$HSC_CONFIG_PATH" ]; then
        echo "${key}: \"${value}\"" > "$HSC_CONFIG_PATH"
        chmod 600 "$HSC_CONFIG_PATH"
        return
    fi
    
    if grep -q "^${key}:" "$HSC_CONFIG_PATH"; then
        sed "s|^${key}:.*|${key}: \"${value}\"|" "$HSC_CONFIG_PATH" > "$tmp_file" && mv "$tmp_file" "$HSC_CONFIG_PATH"
    else
        echo "${key}: \"${value}\"" >> "$HSC_CONFIG_PATH"
    fi
    chmod 600 "$HSC_CONFIG_PATH"
}
