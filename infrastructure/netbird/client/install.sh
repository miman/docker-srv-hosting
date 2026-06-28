#!/bin/bash

# Ensure DOCKER_FOLDER is set
source ../../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Ensure data directory exists
mkdir -p "$DOCKER_FOLDER/netbird"

# Prompt for Setup Key and Hostname 
echo "=================================================================="
echo "                 NetBird Client Configuration"
echo "=================================================================="
echo "To connect this client, you need a NetBird Setup Key."
echo ""
read -p "Enter your NetBird Setup Key: " SETUP_KEY
read -p "Enter Hostname for this client [$(hostname)]: " NB_HOST
echo ""

# Fallback to system hostname if input is blank
export NETBIRD_HOSTNAME=${NB_HOST:-$(hostname)}
export NETBIRD_SETUP_KEY=$SETUP_KEY

if [ -z "$NETBIRD_SETUP_KEY" ]; then
    echo "[WARNING] Setup Key is empty. Container deployment might fail."
fi

# Run the Compose engine
# By explicitly prefixing the variables here, we guarantee they pass to the sub-process
NETBIRD_SETUP_KEY="$NETBIRD_SETUP_KEY" NETBIRD_HOSTNAME="$NETBIRD_HOSTNAME" $COMPOSE_CMD down

NETBIRD_SETUP_KEY="$NETBIRD_SETUP_KEY" NETBIRD_HOSTNAME="$NETBIRD_HOSTNAME" $COMPOSE_CMD pull

NETBIRD_SETUP_KEY="$NETBIRD_SETUP_KEY" NETBIRD_HOSTNAME="$NETBIRD_HOSTNAME" $COMPOSE_CMD up -d

echo "Netbird has been installed"
