#!/bin/bash

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Ensure data directory exists
mkdir -p "$DOCKER_FOLDER/netbird"

# Run the Docker compose file
$COMPOSE_CMD down
$COMPOSE_CMD pull
$COMPOSE_CMD up -d

echo "Netbird has been installed"
