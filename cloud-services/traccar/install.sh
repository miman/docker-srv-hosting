#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Create data directory
mkdir -p "$DOCKER_FOLDER/traccar"

# Run the Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo "Traccar has been installed and is accessible on http://localhost:4411"
