#!/bin/bash
# This script ensures that the DOCKER_FOLDER environment variable is set.
# It first checks if the variable is already set. If not, it attempts to
# read it from the central configuration file ~/.hsc/config.json.
#
# This script is intended to be sourced by other scripts, e.g.:
# source scripts/ensure-DOCKER_FOLDER.sh

# Check if DOCKER_FOLDER is set, otherwise read from config
if [ -z "$DOCKER_FOLDER" ]; then
    CONFIG_FILE="$HOME/.hsc/config.json"
    echo "DOCKER_FOLDER not set, attempting to read from $CONFIG_FILE"
    if [ -f "$CONFIG_FILE" ]; then
        if ! command -v jq > /dev/null; then
            echo "Error: jq is not installed. Please install it to read the config." >&2
            exit 1
        fi
        DOCKER_FOLDER=$(jq -r '.docker_root' "$CONFIG_FILE")
        if [ -z "$DOCKER_FOLDER" ] || [ "$DOCKER_FOLDER" == "null" ]; then
            echo "Error: 'docker_root' not found or is null in $CONFIG_FILE." >&2
            exit 1
        fi
        echo "Successfully read DOCKER_FOLDER from config: $DOCKER_FOLDER"
    else
        echo "Error: DOCKER_FOLDER is not set and $CONFIG_FILE was not found." >&2
        exit 1
    fi
fi

# Export the variable so it's available to sub-processes like docker-compose
export DOCKER_FOLDER
