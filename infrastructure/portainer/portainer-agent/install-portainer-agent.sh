#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

echo "Deploying Portainer Agent Docker container..."

docker compose down
docker compose pull
docker compose up -d --force-recreate

echo "Portainer Agent has been installed and is accessible on port 9001"