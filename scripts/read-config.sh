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
