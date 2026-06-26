#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Set the Uptime Kuma data root based on DOCKER_FOLDER
export UPTIME_KUMA_DATA_ROOT="$DOCKER_FOLDER/uptime-kuma"
mkdir -p "$UPTIME_KUMA_DATA_ROOT/data"

echo "Deploying Uptime Kuma Docker container..."
echo "Data will be stored in: $UPTIME_KUMA_DATA_ROOT/data"

$COMPOSE_CMD down
$COMPOSE_CMD pull
$COMPOSE_CMD up -d --force-recreate

echo "Uptime Kuma has been installed and is accessible on http://localhost:4532"
