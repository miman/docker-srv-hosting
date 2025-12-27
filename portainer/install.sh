#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../scripts/read-config.sh

# Set the Portainer data root based on DOCKER_FOLDER
export PORTAINER_DATA_ROOT="$DOCKER_FOLDER/portainer"
mkdir -p "$PORTAINER_DATA_ROOT/data"

echo "Deploying Portainer Docker container..."
echo "Data will be stored in: $PORTAINER_DATA_ROOT/data"

docker-compose down
docker-compose pull
docker-compose up -d --force-recreate

echo "Portainer has been installed and is accessible on http://localhost:9000"
