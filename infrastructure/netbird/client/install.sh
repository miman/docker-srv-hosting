#!/bin/bash

# Ensure DOCKER_FOLDER is set
source ../../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Ensure data directory exists
mkdir -p "$DOCKER_FOLDER/netbird"

# Prompt for Setup Key and Hostname if placeholder is present in docker-compose.yaml
if grep -q "<SETUP KEY>" docker-compose.yaml || grep -q "<HOSTNAME>" docker-compose.yaml; then
    echo "=================================================================="
    echo "                 NetBird Client Configuration"
    echo "=================================================================="
    echo "To connect this client, you need a NetBird Setup Key."
    echo "If you don't have one, sign up at https://app.netbird.io and create a key."
    echo ""
    read -p "Enter your NetBird Setup Key: " SETUP_KEY
    read -p "Enter Hostname for this client [$(hostname)]: " NETBIRD_HOSTNAME
    NETBIRD_HOSTNAME=${NETBIRD_HOSTNAME:-$(hostname)}
    
    if [ -z "$SETUP_KEY" ]; then
        echo "[WARNING] Setup Key is empty. You will need to manually configure it in docker-compose.yaml."
    else
        # Use sed to update docker-compose.yaml (compatible with macOS and Linux)
        sed -i.bak "s|<SETUP KEY>|$SETUP_KEY|g" docker-compose.yaml
        sed -i.bak "s|<HOSTNAME>|$NETBIRD_HOSTNAME|g" docker-compose.yaml
        rm -f docker-compose.yaml.bak
        echo "[SUCCESS] Configuration applied to docker-compose.yaml!"
    fi
fi

# Run the Docker compose file
$COMPOSE_CMD down
$COMPOSE_CMD pull
$COMPOSE_CMD up -d

echo "Netbird has been installed"
