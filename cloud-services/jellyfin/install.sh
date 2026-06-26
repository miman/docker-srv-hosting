#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Set the Jellyfin data root based on DOCKER_FOLDER
export JELLYFIN_DATA_ROOT="$DOCKER_FOLDER/jellyfin"
mkdir -p "$JELLYFIN_DATA_ROOT/config" "$JELLYFIN_DATA_ROOT/cache" "$JELLYFIN_DATA_ROOT/media" "$JELLYFIN_DATA_ROOT/media2"

# Set the URL dynamically, falling back to localhost if BASE_DNS_NAME isn't set
export JELLYFIN_URL="${BASE_DNS_NAME:+https://jellyfin.$BASE_DNS_NAME}"
export JELLYFIN_URL="${JELLYFIN_URL:-http://localhost:4534}"

echo "Deploying Jellyfin Docker container..."
echo "Data will be stored in: $JELLYFIN_DATA_ROOT/data"

$COMPOSE_CMD down
$COMPOSE_CMD pull
$COMPOSE_CMD up -d --force-recreate

echo "Jellyfin has been installed and is accessible on http://localhost:4534"
