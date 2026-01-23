#!/bin/bash

# Ensure DOCKER_FOLDER is set
source ../scripts/read-config.sh

# Create data directories
mkdir -p "$DOCKER_FOLDER/verdaccio/conf"
mkdir -p "$DOCKER_FOLDER/verdaccio/storage"
mkdir -p "$DOCKER_FOLDER/verdaccio/log"

# Run the Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo "Verdaccio has been installed and is accessible on http://localhost:4873"
