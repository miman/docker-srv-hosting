#!/bin/bash

# Ensure DOCKER_FOLDER is set
source ../scripts/ensure-DOCKER_FOLDER.sh

# Run the Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo "Verdaccio has been installed and is accessible on http://localhost:4873"
