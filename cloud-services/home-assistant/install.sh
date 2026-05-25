#!/bin/bash

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Run the Docker compose file
$COMPOSE_CMD down
$COMPOSE_CMD pull
$COMPOSE_CMD up -d

echo "Home Assistant has been installed and is accessible on http://localhost:8123"
