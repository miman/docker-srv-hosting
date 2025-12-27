#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../scripts/ensure-DOCKER_FOLDER.sh

# Docmost Docker install script for Linux/macOS

# Create docmost directory if it doesn't exist
# This script will place the compose file inside this dir.
if [ ! -d docmost ]; then
  mkdir docmost
fi
cd docmost

# Download the docker-compose.yml file if it doesn't exist
if [ ! -f docker-compose.yml ]; then
  curl -O https://raw.githubusercontent.com/docmost/docmost/main/docker-compose.yml
fi

# --- Modifications for DOCKER_FOLDER ---
echo "Modifying docker-compose.yml to use DOCKER_FOLDER..."
# Note: Using a different separator for sed because DOCKER_FOLDER contains slashes
sed -i "s|      - docmost:/app/data/storage|      - ${DOCKER_FOLDER}/docmost/storage:/app/data/storage|" docker-compose.yml
sed -i "s|      - db_data:/var/lib/postgresql/data|      - ${DOCKER_FOLDER}/docmost/db_data:/var/lib/postgresql/data|" docker-compose.yml
sed -i "s|      - redis_data:/data|      - ${DOCKER_FOLDER}/docmost/redis_data:/data|" docker-compose.yml

# Comment out the top-level volumes block
sed -i "s/^volumes:/# volumes:/" docker-compose.yml
sed -i "s/^  docmost:/#   docmost:/" docker-compose.yml
sed -i "s/^  db_data:/#   db_data:/" docker-compose.yml
sed -i "s/^  redis_data:/#   redis_data:/" docker-compose.yml
echo "Modifications complete."
# ---

# Change the hosting port from 3000 to 4412 in the compose file
if grep -q '"3000:3000"' docker-compose.yml; then
  sed -i 's/"3000:3000"/4412:3000/' docker-compose.yml
fi

# Generate a random UUID (at least 32 chars) for APP_SECRET and replace in the compose file
if grep -q 'REPLACE_WITH_LONG_SECRET' docker-compose.yml; then
    APP_SECRET=$(cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 32)$(cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 8)
    sed -i "s|APP_SECRET: \"REPLACE_WITH_LONG_SECRET\"|APP_SECRET: \"$APP_SECRET\"|" docker-compose.yml
    echo "Generated and set APP_SECRET."
fi


# Prompt user to edit docker-compose.yml for secrets and passwords
echo "Please edit the docker-compose.yml file to set:"
echo "- APP_URL (your domain or http://localhost:4412)"
echo "- STRONG_DB_PASSWORD (replace in POSTGRES_PASSWORD and DATABASE_URL)"
echo "Press Enter to continue after you have finished editing..."
read

# Start the services
docker compose up -d

echo "Docmost is now running. Open http://localhost:4412 or your configured domain to complete setup."