#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../scripts/read-config.sh

# Define and create the data directory for Glance
GLANCE_DATA_DIR="$DOCKER_FOLDER/glance-dashboard"
mkdir -p "$GLANCE_DATA_DIR"
cd "$GLANCE_DATA_DIR"


if [ ! -f docker-compose.yml ]; then
    echo "Downloading Glance configuration files..."
    curl -sL https://github.com/glanceapp/docker-compose-template/archive/refs/heads/main.tar.gz | tar -xzf - --strip-components=2
    
    echo "Updating configuration to use absolute paths..."
    # Assuming the compose file has volumes like './config:/app/config' or './glance.yml:/app/glance.yml'
    # We will replace them to use the full path in GLANCE_DATA_DIR
    if grep -q "./config:/app/config" docker-compose.yml; then
        sed -i "s|./config:/app/config|${GLANCE_DATA_DIR}/config:/app/config|" docker-compose.yml
    fi
    if grep -q "./glance.yml:/app/glance.yml" docker-compose.yml; then
        sed -i "s|./glance.yml:/app/glance.yml|${GLANCE_DATA_DIR}/glance.yml:/app/glance.yml|" docker-compose.yml
    fi

    # Update docker-compose.yml to change port mapping 8080:8080 to 4403:8080
    grep -q -- "- 8080:8080" docker-compose.yml && sed -i 's/- 8080:8080/- 4403:8080/' docker-compose.yml
else
    echo "Glance files already exist. Skipping download and configuration."
fi

echo
echo "Glance configuration is located in: $GLANCE_DATA_DIR"
echo "You can edit docker-compose.yml, config/home.yml, and config/glance.yml there."
echo
read -p "Press Enter to continue..."

# Fetch the latest images
docker compose pull
# Start the containers in detached mode
docker compose up -d

echo "Glance Dashboard is now running. You can access it at http://localhost:4403"
