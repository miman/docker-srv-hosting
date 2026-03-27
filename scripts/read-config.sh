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
# read it from the central configuration file ~/.hsc/config.json.
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
export HSC_CONFIG_PATH="${HSC_CONFIG_PATH:-$HOME/.hsc/config.json}"

# Check if DOCKER_FOLDER is set, otherwise read from config
if [ -z "$DOCKER_FOLDER" ]; then
    echo "DOCKER_FOLDER not set, attempting to read from $HSC_CONFIG_PATH"
    if [ -f "$HSC_CONFIG_PATH" ]; then
        if ! command -v jq > /dev/null; then
            echo "Error: jq is not installed. Please install it to read the config." >&2
            exit 1
        fi
        DOCKER_FOLDER=$(jq -r '.docker_root' "$HSC_CONFIG_PATH")
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
        if ! command -v jq > /dev/null; then
            echo "Error: jq is not installed. Please install it to read the config." >&2
            exit 1
        fi
        BASE_DNS_NAME=$(jq -r '.base_dns_name' "$HSC_CONFIG_PATH")
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
