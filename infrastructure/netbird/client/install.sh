#!/bin/bash

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Ensure data directory exists
mkdir -p "$DOCKER_FOLDER/netbird"

# Run the Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo "Netbird has been installed"
