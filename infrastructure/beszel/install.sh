#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Set the Beszel data root based on DOCKER_FOLDER
export BESZEL_DATA_ROOT="$DOCKER_FOLDER/beszel"
mkdir -p "$BESZEL_DATA_ROOT/data" "$BESZEL_DATA_ROOT/socket" "$BESZEL_DATA_ROOT/agent_data"

# Set the URL dynamically, falling back to localhost if BASE_DNS_NAME isn't set
export BESZEL_URL="${BASE_DNS_NAME:+https://beszel.$BASE_DNS_NAME}"
export BESZEL_URL="${BESZEL_URL:-http://localhost:4533}"

echo "Deploying Beszel Docker container..."
echo "Data will be stored in: $BESZEL_DATA_ROOT/data"

$COMPOSE_CMD down
$COMPOSE_CMD pull
$COMPOSE_CMD up -d --force-recreate

echo "Beszel has been installed and is accessible on http://localhost:4533"
