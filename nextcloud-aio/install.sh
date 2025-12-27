#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../scripts/ensure-DOCKER_FOLDER.sh

# NOTE: The nextcloud-aio/docker-compose.yml is not modified to use DOCKER_FOLDER
# due to explicit warnings in the file to keep the volume configuration as is.
echo "Warning: DOCKER_FOLDER is loaded but not used by this script."


# Run the Docker compose file
docker-compose down
docker-compose pull
docker-compose up -d

echo "Nextcloud-AIO has been installed and is accessible on http://localhost:4504"
