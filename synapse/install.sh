#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Ensure the docker network "local-ai-network" exists
if ! docker network ls --filter name=local-ai-network --format '{{.Name}}' | grep -q "^local-ai-network$"; then
  docker network create local-ai-network
else
  echo "The network local-ai-network already exists."
fi

# Ensure data directory exists
DATA_DIR="$DOCKER_FOLDER/synapse/data"
mkdir -p "$DATA_DIR"

# Generate configuration if it doesn't exist
if [ ! -f "$DATA_DIR/homeserver.yaml" ]; then
    echo "Generating Synapse configuration for $BASE_DNS_NAME..."
    docker run --rm \
        -v "$DATA_DIR:/data" \
        -e SYNAPSE_SERVER_NAME="$BASE_DNS_NAME" \
        -e SYNAPSE_REPORT_STATS=yes \
        matrixdotorg/synapse:latest generate
    
    echo "Configuration generated. Please review $DATA_DIR/homeserver.yaml before deployment."
fi

# Deployment
echo "Deploying Matrix Synapse Docker containers..."
docker compose down
docker compose pull
docker compose up -d --force-recreate
echo "Synapse has been installed and is accessible on http://localhost:4530"
echo "Synapse Admin is accessible on http://localhost:4531"
