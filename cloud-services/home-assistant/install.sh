#!/bin/bash

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Run the Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo "Home Assistant has been installed and is accessible on http://localhost:8123"
