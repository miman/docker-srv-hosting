#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../scripts/ensure-DOCKER_FOLDER.sh

# Create data directories
mkdir -p "$DOCKER_FOLDER/nextcloud/data"
mkdir -p "$DOCKER_FOLDER/nextcloud/db"
mkdir -p "$DOCKER_FOLDER/nextcloud/redis"

# Create .env file from example if it doesn't exist
if [ -f .env ]; then
    echo ".env file already exists, using existing settings."
else
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "!!! IMPORTANT: .env file created from example. Please edit it to set your passwords and domain. !!!"
fi

echo
echo "Please review and edit the .env file to set your admin passwords and trusted domain."
read -p "Press Enter to continue after you have finished editing the .env file..."


# Run the Docker compose file
docker-compose down
docker-compose pull
docker-compose up -d

echo "Nextcloud has been installed and is accessible on http://localhost:4520"
