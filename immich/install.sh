#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../scripts/ensure-DOCKER_FOLDER.sh

# Create data directories
mkdir -p "$DOCKER_FOLDER/immich/library"
mkdir -p "$DOCKER_FOLDER/immich/postgres"
mkdir -p "$DOCKER_FOLDER/immich/model-cache"

# Create .env file
if [ -f .env ]; then
    echo ".env file already exists, using existing settings."
else
    echo "Creating .env file with default settings..."
    cat > .env <<EOF
# The location where your uploaded files are stored
UPLOAD_LOCATION=${DOCKER_FOLDER}/immich/library

# The location where the database data is stored
DB_DATA_LOCATION=${DOCKER_FOLDER}/immich/postgres

# PostgreSQL credentials - CHANGE THIS
DB_USERNAME=postgres
DB_PASSWORD=changeme
DB_DATABASE_NAME=immich

# The version of Immich to use
IMMICH_VERSION=release
EOF
    echo "!!! IMPORTANT: .env file created with a default password. Please change DB_PASSWORD in immich/.env for security. !!!"
fi


# Run the Docker compose file
docker-compose down
docker-compose pull
docker-compose up -d

echo "Immich has been installed."
echo "You can access it at http://<your-ip>:2283"
