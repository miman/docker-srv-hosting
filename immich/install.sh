#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../scripts/read-config.sh

# Ask for installation type
echo "Choose Immich installation type:"
echo "1) Full (recommended, includes machine learning)"
echo "2) Minimal (for devices with limited memory, no machine learning)"
read -p "Enter choice [1 or 2, default: 1]: " choice

case $choice in
    2)
        echo "Selected: Minimal installation"
        IMMICH_PROFILES=""
        ;;
    *)
        echo "Selected: Full installation"
        IMMICH_PROFILES="full"
        ;;
esac

# Create data directories
mkdir -p "$DOCKER_FOLDER/immich/library"
mkdir -p "$DOCKER_FOLDER/immich/postgres"
mkdir -p "$DOCKER_FOLDER/immich/model-cache"

# Create or update .env file
if [ -f .env ]; then
    echo ".env file already exists, updating COMPOSE_PROFILES..."
    if grep -q "COMPOSE_PROFILES" .env; then
        # Use a temporary file for portability with sed
        sed "s/^COMPOSE_PROFILES=.*/COMPOSE_PROFILES=${IMMICH_PROFILES}/" .env > .env.tmp && mv .env.tmp .env
    else
        echo "COMPOSE_PROFILES=${IMMICH_PROFILES}" >> .env
    fi
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

# Profiles to run (empty for minimal, 'full' for machine learning)
COMPOSE_PROFILES=${IMMICH_PROFILES}
EOF
    echo "!!! IMPORTANT: .env file created with a default password. Please change DB_PASSWORD in immich/.env for security. !!!"
fi


# Run the Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo "Immich has been installed ($([ "$IMMICH_PROFILES" = "full" ] && echo "Full" || echo "Minimal") version)."
echo "You can access it at http://<your-ip>:2283"
