#!/bin/bash

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Check if EXTERNAL_DUCKDNS_NAME is set, ask and save if not
if [ -z "$EXTERNAL_DUCKDNS_NAME" ]; then
    read -p "Enter the external DuckDNS name without .duckdns.org suffix (e.g. myservicedomain): " EXTERNAL_DUCKDNS_NAME
    if [ -n "$EXTERNAL_DUCKDNS_NAME" ]; then
        set_config_value ".external_duckdns_name" "$EXTERNAL_DUCKDNS_NAME"
    else
        echo "Error: External DuckDNS name is required."
        exit 1
    fi
fi

# Prompt for token (not stored for security)
if [ -z "$DUCKDNS_TOKEN" ]; then
    read -p "Enter your DuckDNS token for $DUCKDNS_NAME: " DUCKDNS_TOKEN
fi

if [ -z "$DUCKDNS_TOKEN" ]; then
    echo "Error: DuckDNS token is required."
    exit 1
fi

export DUCKDNS_TOKEN

# Run the Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo "DuckDNS updater has been installed for $DUCKDNS_NAME"
